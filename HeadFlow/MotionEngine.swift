import Foundation
import CoreMotion

/// Handles motion updates from compatible headphones (AirPods, Beats)
/// and converts head tilt into scroll events using configurable settings.
@available(macOS 14.0, *)
final class MotionEngine: NSObject, CMHeadphoneMotionManagerDelegate {

    private let manager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()

    // Last measured pitch (degrees) and neutral baseline.
    private var lastPitchDeg: Double?
    private var neutralPitchDeg: Double?

    // Rate limiting for step + auto-read modes
    private var lastStepTime: TimeInterval?
    private var lastAutoReadTime: TimeInterval?

    override init() {
        super.init()
        manager.delegate = self
        queue.name = "HeadFlow.MotionEngineQueue"
    }

    func start() {
        let auth = CMHeadphoneMotionManager.authorizationStatus()
        print("MotionEngine: authorization status = \(auth.rawValue)")
        HeadFlowStatus.shared.updateMotionAuthorization(auth)

        switch auth {
        case .denied, .restricted:
            print("MotionEngine: motion access denied or restricted")
            return
        default:
            break
        }

        guard manager.isDeviceMotionAvailable else {
            print("MotionEngine: device motion not available (no supported headphones?)")
            HeadFlowStatus.shared.setHeadphonesStatus(.notSupported)
            return
        }

        // At this point, motion is available but may not be connected yet.
        HeadFlowStatus.shared.setHeadphonesStatus(.notConnected)

        guard !manager.isDeviceMotionActive else {
            print("MotionEngine: device motion already active")
            return
        }

        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            if let error = error {
                print("MotionEngine: deviceMotion error: \(error)")
                return
            }
            guard let motion = motion else { return }
            self?.handle(motion: motion)
        }

        print("MotionEngine: started device motion updates")
    }

    func stop() {
        guard manager.isDeviceMotionActive else { return }
        manager.stopDeviceMotionUpdates()
        print("MotionEngine: stopped device motion updates")

        // When stopping, we can treat as "not connected" for now.
        HeadFlowStatus.shared.setHeadphonesStatus(.notConnected)
    }

    /// Called whenever new motion data arrives (on our background queue).
    private func handle(motion: CMDeviceMotion) {
        let pitchRad = motion.attitude.pitch
        let pitchDeg = pitchRad * 180.0 / .pi

        lastPitchDeg = pitchDeg

        // Auto-calibrate neutral on first value if needed.
        if neutralPitchDeg == nil {
            neutralPitchDeg = pitchDeg
            print("MotionEngine: auto-calibrated neutral pitch = \(pitchDeg)")
            return
        }

        // Respect user setting (global ON/OFF).
        guard HeadFlowSettings.isHeadScrollingEnabled else { return }

        // Current tuning settings.
        let deadZoneDeg = max(0.0, HeadFlowSettings.deadZoneDegrees)
        let maxTiltDeg  = max(1.0, HeadFlowSettings.maxTiltDegrees) // avoid /0
        let baseLines   = HeadFlowSettings.baseLines()
        let sensitivity = HeadFlowSettings.scrollSensitivity // 0–100
        let mode        = HeadFlowSettings.scrollMode

        // How far from neutral are we?
        guard let neutral = neutralPitchDeg else { return }
        let delta = pitchDeg - neutral

        // If within dead zone, don't scroll at all.
        if abs(delta) < deadZoneDeg {
            return
        }

        // Clamp tilt to max range and map to [-1, 1].
        let clamped = max(-maxTiltDeg, min(maxTiltDeg, delta))
        let factor = clamped / maxTiltDeg              // -1 ... 1
        let magnitude = abs(factor)                    // 0 ... 1

        // Sensitivity factor: 0.5x (0) … 1.5x (100)
        let sensitivityFactor = 0.5 + (sensitivity / 100.0)

        switch mode {
        case .continuous:
            handleContinuousScroll(
                factor: factor,
                magnitude: magnitude,
                baseLines: baseLines,
                sensitivityFactor: sensitivityFactor
            )

        case .step:
            handleStepScroll(
                factor: factor,
                magnitude: magnitude,
                baseLines: baseLines,
                sensitivityFactor: sensitivityFactor
            )

        case .autoRead:
            handleAutoReadScroll(
                factor: factor,
                baseLines: baseLines
            )
        }
    }

    /// Continuous mode: scroll speed scales smoothly with tilt.
    private func handleContinuousScroll(
        factor: Double,
        magnitude: Double,
        baseLines: Int32,
        sensitivityFactor: Double
    ) {
        let linesDouble = Double(baseLines) * magnitude * sensitivityFactor
        let lines = Int32(linesDouble.rounded())
        guard lines > 0 else { return }

        if factor > 0 {
            ScrollEngine.scrollUp(lines: lines)
        } else {
            ScrollEngine.scrollDown(lines: lines)
        }
    }

    /// Step mode: stronger tilt triggers chunked scrolls, rate-limited.
    private func handleStepScroll(
        factor: Double,
        magnitude: Double,
        baseLines: Int32,
        sensitivityFactor: Double
    ) {
        // Require a minimum magnitude to trigger a step.
        let triggerThreshold = 0.4  // 0...1; tweak after real testing
        guard magnitude > triggerThreshold else { return }

        // Rate limit: at most one step every 150 ms.
        let now = CFAbsoluteTimeGetCurrent()
        let minInterval: TimeInterval = 0.15
        if let last = lastStepTime, now - last < minInterval {
            return
        }
        lastStepTime = now

        // Step size: bigger than continuous.
        let stepLinesDouble = Double(baseLines) * sensitivityFactor * 1.5
        let stepLines = Int32(stepLinesDouble.rounded())
        let lines = max(Int32(1), stepLines)

        if factor > 0 {
            ScrollEngine.scrollUp(lines: lines)
        } else {
            ScrollEngine.scrollDown(lines: lines)
        }
    }

    /// Auto-read mode: tilt down slightly to trigger slow downward scroll,
    /// with a fixed max frequency (like a teleprompter tick).
    private func handleAutoReadScroll(
        factor: Double,
        baseLines: Int32
    ) {
        // Only scroll when tilted down (negative factor).
        guard factor < 0 else { return }

        // Rate limit: e.g. 20 times per second (every 0.05 s).
        let now = CFAbsoluteTimeGetCurrent()
        let minInterval: TimeInterval = 0.05
        if let last = lastAutoReadTime, now - last < minInterval {
            return
        }
        lastAutoReadTime = now

        // Slow, constant scroll for reading.
        let lines = max(Int32(1), Int32(Double(baseLines) * 0.3))
        ScrollEngine.scrollDown(lines: lines)
    }

    /// Manually re-calibrate the neutral head position.
    func calibrateNeutral() {
        if let last = lastPitchDeg {
            neutralPitchDeg = last
            print("MotionEngine: manually calibrated neutral pitch = \(last)")
        } else {
            // If we haven't received data yet, let auto-calibration handle it.
            neutralPitchDeg = nil
            print("MotionEngine: no motion samples yet – will auto-calibrate on next sample")
        }
    }

    // MARK: - CMHeadphoneMotionManagerDelegate

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones connected")
        HeadFlowStatus.shared.setHeadphonesStatus(.connected)
        neutralPitchDeg = nil
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones disconnected")
        HeadFlowStatus.shared.setHeadphonesStatus(.notConnected)
        neutralPitchDeg = nil
    }
}
