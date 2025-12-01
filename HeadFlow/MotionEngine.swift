//MotionEngine
import Foundation
import CoreMotion
import AppKit

/// Handles motion updates from compatible headphones (AirPods, Beats)
/// and converts head tilt into scroll events using configurable settings.
@available(macOS 14.0, *)
final class MotionEngine: NSObject, CMHeadphoneMotionManagerDelegate {
    
    private enum PauseReason {
        case pointer
        case typing
        case modifier
        case manualScroll
        case dictation
    }
    
    private let manager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()

    // Last measured pitch (degrees) and neutral baseline.
    private var lastPitchDeg: Double?
    private var neutralPitchDeg: Double?
    
    private var lastYawDeg: Double?     // Track last yaw for calibration
    private var neutralYawDeg: Double?  // Baseline for "center" cursor position
    private let cursorLogic = CursorLogic()

    // Continuous mode: smoothed velocity (lines per second) + accumulator.
    private var lastContinuousTime: TimeInterval?
    private var continuousCurrentSpeed: Double = 0.0   // lines / second
    private var continuousAccumulator: Double = 0.0

    // Auto-read mode: smoothed downward velocity + accumulator.
    private var lastAutoReadTime: TimeInterval?
    private var autoReadCurrentSpeed: Double = 0.0     // lines / second (downward)
    private var autoReadAccumulator: Double = 0.0
    
    // MARK: - Gesture detection state

   /// Last time each gesture fired, for per-gesture cooldown.
    private var lastGestureFireTime: [GestureType: CFAbsoluteTime] = [:]

   /// Simple edge-detection so we only fire once when crossing thresholds.
    private var isTiltLeftEngaged = false
    private var isTiltRightEngaged = false
    
    // Tuning constants for acceleration / damping feel (seconds).
    // Smaller = snappier, larger = more "heavy" / inertial.
    private let baseTauContinuousUp: Double = 0.14   // ramp-up
    private let baseTauContinuousDown: Double = 0.40 // ramp-down

    private let baseTauAutoReadUp: Double = 0.25
    private let baseTauAutoReadDown: Double = 0.55


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
            DispatchQueue.main.async {
                MotionLiveState.shared.status = .needsSetup
            }
            return
        default:
            break
        }

        guard manager.isDeviceMotionAvailable else {
            print("MotionEngine: device motion not available (no supported headphones?)")
            HeadFlowStatus.shared.setHeadphonesStatus(.notSupported)
            DispatchQueue.main.async {
                MotionLiveState.shared.status = .disconnected
            }
            return
        }

        // At this point, motion is available but may not be connected yet.
        HeadFlowStatus.shared.setHeadphonesStatus(.notConnected)
        DispatchQueue.main.async {
            let phones = HeadphoneDeviceState.shared
            phones.isConnected = false
            phones.deviceName = nil
            phones.kind = .none
        }

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

    /// Immediately stop all scrolling and reset timing + live state.
    private func hardStopScrolling() {
        lastContinuousTime = nil
        continuousCurrentSpeed = 0.0
        continuousAccumulator = 0.0

        lastAutoReadTime = nil
        autoReadCurrentSpeed = 0.0
        autoReadAccumulator = 0.0

        DispatchQueue.main.async {
            let live = MotionLiveState.shared
            live.velocityLinesPerSecond = 0.0
            live.tiltPercent = 0.0
            live.tiltDegrees = 0.0
            live.status = .idle
        }
    }
    
    private func publishPausedStatus(_ reason: PauseReason) {
        DispatchQueue.main.async {
            let live = MotionLiveState.shared
            switch reason {
            case .pointer:
                live.status = .pausedPointer
            case .typing:
                live.status = .pausedTyping
            case .modifier:
                live.status = .pausedModifier
            case .manualScroll:
                live.status = .pausedManualScroll
            case .dictation:
                live.status = .pausedDictation
            }
            live.velocityLinesPerSecond = 0.0
        }
    }

    /// Called whenever new motion data arrives (on our background queue).
    private func handle(motion: CMDeviceMotion) {
            // 🔐 License gate: if trial expired and not unlocked, do nothing.
            if !AccessGate.hasFullAccess {
                hardStopScrolling()
                return
            }
        
            let pitchRad = motion.attitude.pitch
            let pitchDeg = pitchRad * 180.0 / .pi
            
            // --- ADD: Calculate Yaw and Roll ---
            let yawRad = motion.attitude.yaw
            let yawDeg = yawRad * 180.0 / .pi
            let rollRad = motion.attitude.roll
            let rollDeg = rollRad * 180.0 / .pi
            // -----------------------------------

            lastPitchDeg = pitchDeg
            lastYawDeg = yawDeg // <--- ADD THIS

            // Auto-calibrate neutral on first value if needed.
            if neutralPitchDeg == nil {
                neutralPitchDeg = pitchDeg
                neutralYawDeg = yawDeg // <--- ADD THIS
                print("MotionEngine: auto-calibrated neutral pitch = \(pitchDeg)")
                return
            }
            
            // --- UPDATE: Unwrap both neutrals ---
            guard let neutralP = neutralPitchDeg, let neutralY = neutralYawDeg else { return }
            let delta = pitchDeg - neutralP
            
            // Calculate Yaw Delta (Joystick X input) with wrap-around fix
            var deltaYaw = yawDeg - neutralY
            if deltaYaw > 180 { deltaYaw -= 360 }
            if deltaYaw < -180 { deltaYaw += 360 }
            // ------------------------------------

            // Resolve effective config for current app.
            let bundleID = DispatchQueue.main.sync {
                NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            }
            let config = ProfileManager.shared.effectiveConfig(for: bundleID)
            let mode = config.scrollMode // <--- Moved up for safety check use
        
            // 🔹 Always run gesture detection, even when HeadFlow scrolling is OFF.
            if mode != .cursor {
                detectGestures(motion: motion, deltaPitch: delta)
            }
            // Global ON/OFF must be respected first.
            guard HeadFlowSettings.isHeadScrollingEnabled else {
                hardStopScrolling()
                return
            }

            // Also respect per-app enable flag.
            guard config.isEnabled else {
                hardStopScrolling()
                return
            }
        
            if HeadFlowSettings.dictationPausesHeadFlow,
               DictationRuntimeState.shared.isDictating {
                hardStopScrolling()
                publishPausedStatus(.dictation)
                return
            }
            
            // Smart pause: if user recently scrolled manually, back off briefly.
            if ManualScrollPauseController.shared.isPausedForManualScroll {
                hardStopScrolling()
                publishPausedStatus(.manualScroll)
                return
            }
            
            // --- Safety: Shift clutch ---
            if HeadFlowSettings.shiftToPauseEnabled,
               NSEvent.modifierFlags.contains(.shift) {
                hardStopScrolling()
                publishPausedStatus(.modifier)
                return
            }

            // --- Safety: pointer movement ---
            // UPDATE: Skip this check if we are in Cursor Mode (otherwise head movement pauses itself)
            if mode != .cursor, // <--- ADD THIS CONDITION
               HeadFlowSettings.pauseWhilePointerActive,
               PointerActivityMonitor.shared.isRecentlyActive(threshold: 0.25) {
                hardStopScrolling()
                publishPausedStatus(.pointer)
                return
            }

            // --- Safety: typing activity ---
            if HeadFlowSettings.pauseWhileTyping,
               TypingActivityMonitor.shared.isRecentlyActive(threshold: 0.40) {
                hardStopScrolling()
                publishPausedStatus(.typing)
                return
            }

            // Current tuning settings for this app.
            let deadZoneDeg = max(0.0, config.deadZoneDegrees)
            let maxTiltDeg  = max(1.0, config.maxTiltDegrees)
            let baseLines   = max(Int32(0), min(Int32(500), config.baseLines))
            let sensitivity = max(0.0, min(100.0, config.scrollSensitivity))
            
            // Map tilt to [-1, 1] and magnitude to [0, 1].
            var factor: Double = 0.0
            var magnitude: Double = 0.0

            if abs(delta) >= deadZoneDeg {
                let clamped = max(-maxTiltDeg, min(maxTiltDeg, delta))
                factor = clamped / maxTiltDeg
                magnitude = abs(factor)
            }

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
                
            // --- ADD THIS CASE ---
            case .cursor:
                // In cursor mode:
                // - deltaYaw (turn left/right) controls horizontal cursor movement (X)
                // - delta (pitch up/down) controls vertical cursor movement (Y)
                // - deltaYaw also triggers clicks when turning with Command held
                
                // Pass to cursor logic for processing
                cursorLogic.update(yaw: deltaYaw, pitch: delta, roll: rollDeg)
                
                // Update live state for cursor mode
                DispatchQueue.main.async {
                    let live = MotionLiveState.shared
                    live.mode = .cursor
                    live.status = .tracking
                    live.tiltDegrees = deltaYaw  // Show yaw angle for click feedback
                    live.tiltPercent = 0.0
                    live.velocityLinesPerSecond = 0.0
                }
            // ---------------------
            }

            // After updating scroll, publish live state for the UI.
            publishLiveState(
                tiltDeltaDegrees: delta,
                maxTiltDegrees: maxTiltDeg,
                mode: mode
            )
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
        
        // Map user tuning (0.5x ... 2.0x) to time constants.
        let accelFactor = max(0.5, min(5.0, HeadFlowSettings.accelerationFactor))
        let dampingFactor = max(0.5, min(5.0, HeadFlowSettings.dampingFactor))

        // Baseline time constants (seconds).
        let baseTauUp: Double = 0.14   // how fast we ramp up
        let baseTauDown: Double = 0.40 // how fast we slow down

        let tauUp = baseTauUp / accelFactor      // higher accelFactor = snappier
        let tauDown = baseTauDown / dampingFactor // higher dampingFactor = quicker stop

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

        // --- Acceleration vs damping for "ball-like" inertia ---

        // Are we trying to go faster than our current speed? (accelerating)
        let accelerating = abs(targetSpeed) > abs(continuousCurrentSpeed)

        // Pick time constant based on whether we’re ramping up or down.
        let tau = accelerating ? tauUp : tauDown

        // Exponential smoothing factor based on dt and tau.
        let alpha = 1.0 - exp(-dt / tau)   // 0...1

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
        
        // Map user tuning (0.5x ... 2.0x) to time constants.
        let accelFactor = max(0.5, min(5.0, HeadFlowSettings.accelerationFactor))
        let dampingFactor = max(0.5, min(5.0, HeadFlowSettings.dampingFactor))

        // Baseline time constants (seconds) for auto-read.
        let baseTauUp: Double = 0.25
        let baseTauDown: Double = 0.55

        let tauUp = baseTauUp / accelFactor
        let tauDown = baseTauDown / dampingFactor

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

        // --- Acceleration vs damping for auto-read inertia ---

        // Target downward speed (always positive, lines/sec).
        let targetSpeed = maxLinesPerSecond * effectiveMagnitude

        // Acceleration vs damping for auto-read inertia.
        let accelerating = targetSpeed > autoReadCurrentSpeed
        let tau = accelerating ? tauUp : tauDown
        let alpha = 1.0 - exp(-dt / tau)

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

    /// Publish live tilt / velocity / status for the Preferences UI.
    private func publishLiveState(
        tiltDeltaDegrees delta: Double,
        maxTiltDegrees: Double,
        mode: ScrollMode
    ) {
        // Clamp tilt to max range for display.
        let clampedDelta = max(-maxTiltDegrees, min(maxTiltDegrees, delta))
        let tiltPercent: Double
        if maxTiltDegrees > 0 {
            tiltPercent = (clampedDelta / maxTiltDegrees) * 100.0
        } else {
            tiltPercent = 0.0
        }

        // Velocity source depends on mode.
        let velocityLps: Double
        switch mode {
        case .continuous:
            velocityLps = continuousCurrentSpeed
        case .autoRead:
            velocityLps = -autoReadCurrentSpeed
        case .cursor:
            velocityLps = 0.0
        }

        // Decide status for UI based on current app / permissions.
        let statusModel = HeadFlowStatus.shared
        let status: MotionLiveState.Status

        if !HeadFlowSettings.isHeadScrollingEnabled {
            status = .idle
        } else if statusModel.accessibility != .enabled || statusModel.motionAuth != .authorized {
            status = .needsSetup
        } else if statusModel.headphones != .connected {
            status = .disconnected
        } else {
            status = .tracking
        }

        DispatchQueue.main.async {
            let live = MotionLiveState.shared
            live.tiltDegrees = clampedDelta
            live.tiltPercent = tiltPercent
            live.velocityLinesPerSecond = velocityLps
            live.mode = mode
            live.status = status
        }
    }

    /// Manually re-calibrate the neutral head position.
    func calibrateNeutral() {
        // Reset any ongoing state first
        hardStopScrolling()
        
        if let lastP = lastPitchDeg, let lastY = lastYawDeg {
            neutralPitchDeg = lastP
            neutralYawDeg = lastY
            
            // Get current mode to check if we're in cursor mode
            // Use async to avoid deadlock if called from main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                let config = ProfileManager.shared.effectiveConfig(for: bundleID)
                
                // If in cursor mode, center the cursor on screen
                if config.scrollMode == .cursor {
                    CursorEngine.centerCursor()
                    self.cursorLogic.resetSmoothing()
                    print("MotionEngine: Calibrated neutral (P: \(lastP), Y: \(lastY)) + centered cursor")
                } else {
                    print("MotionEngine: Calibrated neutral (P: \(lastP), Y: \(lastY))")
                }
            }
        } else {
            neutralPitchDeg = nil
            neutralYawDeg = nil
            print("MotionEngine: No motion samples yet – will auto-calibrate on next sample")
        }
    }

    // MARK: - CMHeadphoneMotionManagerDelegate

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones connected")
        HeadFlowStatus.shared.setHeadphonesStatus(.connected)
        neutralPitchDeg = nil
        neutralYawDeg = nil
        hardStopScrolling()

        DispatchQueue.main.async {
            let phones = HeadphoneDeviceState.shared
            phones.isConnected = true
            phones.deviceName = "Headphones"
            phones.kind = .other
            
            // Center cursor when headphones connect
            CursorEngine.centerCursor()
        }
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones disconnected")
        HeadFlowStatus.shared.setHeadphonesStatus(.notConnected)
        neutralPitchDeg = nil
        neutralYawDeg = nil
        hardStopScrolling()

        DispatchQueue.main.async {
            let phones = HeadphoneDeviceState.shared
            phones.isConnected = false
            phones.deviceName = nil
            phones.kind = .none
        }
    }
    
    // MARK: - Gesture detection helpers

    /// Returns true if this gesture can fire (cooldown passed).
    private func canFireGesture(_ gesture: GestureType,
                                cooldown: TimeInterval,
                                now: CFAbsoluteTime) -> Bool {
        if let last = lastGestureFireTime[gesture], now - last < cooldown {
            return false
        }
        return true
    }

    /// Record fire time and send gesture to the dispatcher.
    private func fireGesture(_ gesture: GestureType,
                             context: GestureContext,
                             now: CFAbsoluteTime) {
        lastGestureFireTime[gesture] = now
        GestureDispatcher.shared.handle(gesture: gesture, context: context)
    }

    /// Detect tilt left/right gestures using ROLL (side-to-side head tilt).
    /// Runs on every motion sample, regardless of HeadFlow scrolling ON/OFF.
    private func detectGestures(motion: CMDeviceMotion, deltaPitch: Double) {
        let now = CFAbsoluteTimeGetCurrent()
        let context: GestureContext = HeadFlowSettings.isHeadScrollingEnabled ? .headFlowOn : .headFlowOff

        // User-tunable thresholds.
        // Clamp to reasonable ranges so bad values don't break detection.
        let tiltThreshold = max(5.0, min(90.0, HeadFlowSettings.gestureTiltThresholdDegrees))
        let gestureCooldown = max(0.1, min(5.0, HeadFlowSettings.gestureCooldownSeconds))

        // Get roll and yaw rotation axes for robust detection.
        let rollRad = motion.attitude.roll
        let yawRad = motion.attitude.yaw
        
        // Convert to degrees.
        var rollDeg = rollRad * 180.0 / .pi
        let yawDeg = yawRad * 180.0 / .pi
        
        // Normalize roll to [-180, 180] range to handle wrap-around.
        // This fixes detection at high angles (45-80 degrees).
        if rollDeg > 180 {
            rollDeg -= 360
        } else if rollDeg < -180 {
            rollDeg += 360
        }
        
        // For large rotations, combine roll + yaw for more natural detection.
        // When you rotate your head far, it's a mix of roll and yaw.
        let combinedTiltRight = rollDeg + (yawDeg > 0 ? yawDeg * 0.3 : 0)
        let combinedTiltLeft = rollDeg - (yawDeg < 0 ? abs(yawDeg) * 0.3 : 0)
        
        // Calculate hysteresis threshold (85% for smoother reset).
        let hysteresisThreshold = tiltThreshold * 0.85

        // Detect TILT RIGHT (head tilts toward right shoulder).
        // Positive roll = tilting right.
        if combinedTiltRight >= tiltThreshold {
            if !isTiltRightEngaged {
                // Check cooldown before firing.
                if canFireGesture(.tiltRight, cooldown: gestureCooldown, now: now) {
                    isTiltRightEngaged = true
                    fireGesture(.tiltRight, context: context, now: now)
                }
            }
        } else if combinedTiltRight < hysteresisThreshold {
            // Reset with hysteresis to avoid flickering.
            isTiltRightEngaged = false
        }

        // Detect TILT LEFT (head tilts toward left shoulder).
        // Negative roll = tilting left.
        if combinedTiltLeft <= -tiltThreshold {
            if !isTiltLeftEngaged {
                // Check cooldown before firing.
                if canFireGesture(.tiltLeft, cooldown: gestureCooldown, now: now) {
                    isTiltLeftEngaged = true
                    fireGesture(.tiltLeft, context: context, now: now)
                }
            }
        } else if combinedTiltLeft > -hysteresisThreshold {
            // Reset with hysteresis to avoid flickering.
            isTiltLeftEngaged = false
        }
    }

}
