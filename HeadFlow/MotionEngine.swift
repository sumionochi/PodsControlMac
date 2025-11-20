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

    // Continuous mode: smoothed velocity (lines per second) + accumulator.
    private var lastContinuousTime: TimeInterval?
    private var continuousCurrentSpeed: Double = 0.0   // lines / second
    private var continuousAccumulator: Double = 0.0

    // Auto-read mode: smoothed downward velocity + accumulator.
    private var lastAutoReadTime: TimeInterval?
    private var autoReadCurrentSpeed: Double = 0.0     // lines / second (downward)
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
        hardStopScrolling()
    }

    /// Safely get the bundle ID of the frontmost application.
    private func frontmostBundleID() -> String? {
        var id: String?
        DispatchQueue.main.sync {
            id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        }
        return id
    }

    /// Immediately stop all scrolling and reset timing.
    private func hardStopScrolling() {
        lastContinuousTime = nil
        continuousCurrentSpeed = 0.0
        continuousAccumulator = 0.0

        lastAutoReadTime = nil
        autoReadCurrentSpeed = 0.0
        autoReadAccumulator = 0.0
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
            hardStopScrolling()
            return
        }

        // Resolve effective config for current app.
        let bundleID = frontmostBundleID()
        let config = ProfileManager.shared.effectiveConfig(for: bundleID)

        // Also respect per-app enable flag.
        guard config.isEnabled else {
            hardStopScrolling()
            return
        }

        // Current tuning settings for this app.
        let deadZoneDeg = max(0.0, config.deadZoneDegrees)
        let maxTiltDeg  = max(1.0, config.maxTiltDegrees) // avoid /0
        let baseLines   = max(Int32(0), min(Int32(500), config.baseLines)) // safety clamp
        let sensitivity = max(0.0, min(100.0, config.scrollSensitivity))   // 0–100
        let mode        = config.scrollMode

        // How far from neutral are we?
        guard let neutral = neutralPitchDeg else { return }
        let delta = pitchDeg - neutral

        // Map tilt to [-1, 1] and magnitude to [0, 1], but treat dead zone
        // as "no tilt" (factor = 0, magnitude = 0) so smoothing can ease to 0.
        var factor: Double = 0.0     // -1...1, sign gives direction (up/down)
        var magnitude: Double = 0.0  // 0...1, how strong the tilt is

        if abs(delta) >= deadZoneDeg {
            let clamped = max(-maxTiltDeg, min(maxTiltDeg, delta))
            factor = clamped / maxTiltDeg
            magnitude = abs(factor)
        }

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

    // MARK: - Continuous mode (smoothed)

    /// Continuous mode: scroll speed scales with tilt, using a smoothed
    /// velocity (lines per second) so start/stop feel gradual.
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
        // Clamp dt to avoid huge jumps if updates pause.
        dt = max(0.0, min(dt, 0.1))
        lastContinuousTime = now

        guard dt > 0 else { return }

        // Max possible speed at full tilt (magnitude = 1).
        let maxLinesPerSecond = Double(baseLines) * speedMultiplier

        // Desired speed based on current tilt. If we're inside the dead zone,
        // factor and magnitude will both be 0 → targetSpeed = 0.
        let direction: Double
        if factor > 0 {
            direction = 1.0
        } else if factor < 0 {
            direction = -1.0
        } else {
            direction = 0.0
        }

        let targetSpeed = maxLinesPerSecond * magnitude * direction   // lines / second

        // Smooth speed changes with an exponential filter so we ease in/out.
        // tau ≈ 0.15s → feels responsive but not jerky.
        let responseTime: Double = 0.15
        let alpha = 1.0 - exp(-dt / responseTime)   // 0...1

        continuousCurrentSpeed += (targetSpeed - continuousCurrentSpeed) * alpha

        // Snap very small speeds to zero to avoid tiny residual drift.
        if abs(continuousCurrentSpeed) < 0.01 {
            continuousCurrentSpeed = 0.0
        }

        // Integrate speed over time to get how many lines to scroll.
        continuousAccumulator += continuousCurrentSpeed * dt

        // Use the integer part and keep the fractional remainder.
        let linesToScroll = Int32(continuousAccumulator)

        if linesToScroll == 0 { return }

        continuousAccumulator -= Double(linesToScroll)

        if linesToScroll > 0 {
            ScrollEngine.scrollUp(lines: linesToScroll)
        } else {
            ScrollEngine.scrollDown(lines: -linesToScroll)
        }
    }

    // MARK: - Auto-read mode (smoothed)

    /// Auto-read mode: tilt down slightly to trigger slow downward scroll,
    /// using a smoothed "lines per second" model so it eases in/out like
    /// a teleprompter.
    private func handleAutoReadScroll(
        factor: Double,
        magnitude: Double,
        baseLines: Int32,
        speedMultiplier: Double
    ) {
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

        // Only scroll when tilted down. When factor >= 0, targetSpeed = 0 and
        // smoothing will gracefully decelerate to a stop.
        let minMagnitudeForScroll = 0.05
        let effectiveMagnitude: Double
        if factor >= 0 || magnitude <= minMagnitudeForScroll {
            effectiveMagnitude = 0.0
        } else {
            // Re-map [minMag, 1] → [0, 1]
            effectiveMagnitude = (magnitude - minMagnitudeForScroll) / (1.0 - minMagnitudeForScroll)
        }

        // Target downward speed (always positive, lines/sec).
        let targetSpeed = maxLinesPerSecond * effectiveMagnitude

        // Smooth speed changes; slightly more relaxed than continuous.
        let responseTime: Double = 0.25
        let alpha = 1.0 - exp(-dt / responseTime)

        autoReadCurrentSpeed += (targetSpeed - autoReadCurrentSpeed) * alpha

        if autoReadCurrentSpeed < 0.01 {
            autoReadCurrentSpeed = 0.0
        }

        // Integrate downward speed.
        autoReadAccumulator += autoReadCurrentSpeed * dt

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
        hardStopScrolling()
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones disconnected")
        HeadFlowStatus.shared.setHeadphonesStatus(.notConnected)
        neutralPitchDeg = nil
        hardStopScrolling()
    }
}
