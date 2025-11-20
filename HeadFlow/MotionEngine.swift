import Foundation
import CoreMotion
import AppKit

/// Handles motion updates from compatible headphones (AirPods, Beats)
/// and converts head tilt into scroll events using configurable settings.
@available(macOS 14.0, *)
final class MotionEngine: NSObject, CMHeadphoneMotionManagerDelegate {

    private let manager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()

    // Last measured pitch (degrees) and neutral baseline.
    private var lastPitchDeg: Double?
    private var neutralPitchDeg: Double?

    // Timing & accumulators for different modes.
    // Step mode still uses a simple time-based rate limiter.
    private var lastStepTime: TimeInterval?

    // Continuous mode: time-based velocity with signed accumulator.
    private var lastContinuousTime: TimeInterval?
    private var continuousAccumulator: Double = 0.0

    // Auto-read mode: time-based velocity with downward-only accumulator.
    private var lastAutoReadTime: TimeInterval?
    private var autoReadAccumulator: Double = 0.0

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

        HeadFlowStatus.shared.setHeadphonesStatus(.notConnected)
    }

    /// Safely get the bundle ID of the frontmost application.
    private func frontmostBundleID() -> String? {
        var id: String?
        DispatchQueue.main.sync {
            id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        }
        return id
    }

    /// Reset timing/accumulators when we’re in the dead zone (no scrolling).
    private func resetScrollStateOnNeutral() {
        lastContinuousTime = nil
        continuousAccumulator = 0.0
        lastAutoReadTime = nil
        autoReadAccumulator = 0.0
        // Step mode just uses a coarse rate limit; no reset needed.
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

        // Global ON/OFF must be respected first.
        guard HeadFlowSettings.isHeadScrollingEnabled else {
            resetScrollStateOnNeutral()
            return
        }

        // Resolve effective config for current app.
        let bundleID = frontmostBundleID()
        let config = ProfileManager.shared.effectiveConfig(for: bundleID)

        // Also respect per-app enable flag.
        guard config.isEnabled else {
            resetScrollStateOnNeutral()
            return
        }

        // Current tuning settings for this app.
        let deadZoneDeg = max(0.0, config.deadZoneDegrees)
        let maxTiltDeg  = max(1.0, config.maxTiltDegrees) // avoid /0
        let baseLines   = max(Int32(0), min(Int32(500), config.baseLines)) // safety clamp
        let sensitivity = max(0.0, min(100.0, config.scrollSensitivity)) // 0–100
        let mode        = config.scrollMode

        // How far from neutral are we?
        guard let neutral = neutralPitchDeg else { return }
        let delta = pitchDeg - neutral

        // If within dead zone, don't scroll at all and reset timing.
        if abs(delta) < deadZoneDeg {
            resetScrollStateOnNeutral()
            return
        }

        // Clamp tilt to max range and map to [-1, 1].
        let clamped = max(-maxTiltDeg, min(maxTiltDeg, delta))
        let factor = clamped / maxTiltDeg              // -1 ... 1
        let magnitude = abs(factor)                    // 0 ... 1

        // Map sensitivity slider (0–100) to a wide speed multiplier range.
        // 0  → very slow (0.1x)
        // 100 → very fast (4.0x)
        let sensitivityNorm = sensitivity / 100.0
        let minSpeedMultiplier: Double = 0.1
        let maxSpeedMultiplier: Double = 4.0
        let speedMultiplier = minSpeedMultiplier + (maxSpeedMultiplier - minSpeedMultiplier) * sensitivityNorm

        switch mode {
        case .continuous:
            handleContinuousScroll(
                factor: factor,
                magnitude: magnitude,
                baseLines: baseLines,
                speedMultiplier: speedMultiplier
            )

        case .autoRead:
            handleAutoReadScroll(
                factor: factor,
                magnitude: magnitude,
                baseLines: baseLines,
                speedMultiplier: speedMultiplier
            )
        }
    }

    // MARK: - Continuous mode

    /// Continuous mode: scroll speed scales smoothly with tilt, using a
    /// time-based "lines per second" model and an accumulator so we
    /// can get *truly* slow or fast scrolling.
    private func handleContinuousScroll(
        factor: Double,
        magnitude: Double,
        baseLines: Int32,
        speedMultiplier: Double
    ) {
        let now = CFAbsoluteTimeGetCurrent()

        // First sample → just initialize timestamp.
        guard let lastTime = lastContinuousTime else {
            lastContinuousTime = now
            return
        }

        var dt = now - lastTime
        // Clamp dt to avoid huge jumps after pauses.
        dt = max(0.0, min(dt, 0.1))
        lastContinuousTime = now

        guard dt > 0 else { return }

        // Base "max lines per second" at full tilt, then scale by sensitivity.
        let maxLinesPerSecond = Double(baseLines) * speedMultiplier

        // Scale by magnitude (0...1) to get actual velocity.
        let linesPerSecond = maxLinesPerSecond * magnitude

        // Direction: up for positive tilt, down for negative.
        let direction = factor > 0 ? 1.0 : -1.0

        // Accumulate signed lines.
        continuousAccumulator += linesPerSecond * direction * dt

        // Emit only the integer part, keep fractional remainder.
        let linesToScroll = Int32(continuousAccumulator)

        if linesToScroll == 0 { return }

        continuousAccumulator -= Double(linesToScroll)

        if linesToScroll > 0 {
            ScrollEngine.scrollUp(lines: linesToScroll)
        } else {
            ScrollEngine.scrollDown(lines: -linesToScroll)
        }
    }

    // MARK: - Auto-read mode

    /// Auto-read mode: tilt down slightly to trigger slow downward scroll,
    /// using a time-based "lines per second" model. Sensitivity and baseLines
    /// both influence the pace.
    private func handleAutoReadScroll(
        factor: Double,
        magnitude: Double,
        baseLines: Int32,
        speedMultiplier: Double
    ) {
        // Only scroll when tilted down (negative factor).
        guard factor < 0 else {
            // Reset timing when we are no longer in auto-read posture.
            lastAutoReadTime = nil
            autoReadAccumulator = 0.0
            return
        }

        let now = CFAbsoluteTimeGetCurrent()

        // First sample → just initialize timestamp.
        guard let lastTime = lastAutoReadTime else {
            lastAutoReadTime = now
            return
        }

        var dt = now - lastTime
        dt = max(0.0, min(dt, 0.2))  // auto-read is forgiving; allow a bit more.
        lastAutoReadTime = now

        guard dt > 0 else { return }

        // For auto-read, we use a more conservative max speed so it feels
        // like a teleprompter: half of continuous' max by default.
        let autoReadGlobalFactor: Double = 0.5
        let maxLinesPerSecond = Double(baseLines) * speedMultiplier * autoReadGlobalFactor

        // Ignore tiny tilts so you can sit near neutral without jitter.
        let minMagnitudeForScroll = 0.05
        let effectiveMagnitude: Double
        if magnitude <= minMagnitudeForScroll {
            effectiveMagnitude = 0.0
        } else {
            // Re-map [minMag, 1] → [0, 1]
            effectiveMagnitude = (magnitude - minMagnitudeForScroll) / (1.0 - minMagnitudeForScroll)
        }

        let linesPerSecond = maxLinesPerSecond * effectiveMagnitude

        // Accumulate lines to scroll down (always positive).
        autoReadAccumulator += linesPerSecond * dt

        let linesToScroll = Int32(autoReadAccumulator)
        guard linesToScroll > 0 else { return }

        autoReadAccumulator -= Double(linesToScroll)
        ScrollEngine.scrollDown(lines: linesToScroll)
    }

    /// Manually re-calibrate the neutral head position.
    func calibrateNeutral() {
        if let last = lastPitchDeg {
            neutralPitchDeg = last
            print("MotionEngine: manually calibrated neutral pitch = \(last)")
        } else {
            neutralPitchDeg = nil
            print("MotionEngine: no motion samples yet – will auto-calibrate on next sample")
        }
    }

    // MARK: - CMHeadphoneMotionManagerDelegate

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones connected")
        HeadFlowStatus.shared.setHeadphonesStatus(.connected)
        neutralPitchDeg = nil
        resetScrollStateOnNeutral()
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones disconnected")
        HeadFlowStatus.shared.setHeadphonesStatus(.notConnected)
        neutralPitchDeg = nil
        resetScrollStateOnNeutral()
    }
}
