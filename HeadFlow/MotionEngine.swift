import Foundation
import CoreMotion

/// Handles motion updates from compatible headphones (AirPods, Beats)
/// and converts head tilt into scroll events.
@available(macOS 14.0, *)
final class MotionEngine: NSObject, CMHeadphoneMotionManagerDelegate {

    private let manager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()

    // Last measured pitch (degrees) and neutral baseline.
    private var lastPitchDeg: Double?
    private var neutralPitchDeg: Double?

    // Tuning constants.
    private let deadZoneDeg: Double = 3.0    // no scroll if tilt is within ±3°
    private let maxTiltDeg: Double = 25.0    // clamp tilt to ±25° before mapping to speed

    override init() {
        super.init()
        manager.delegate = self
        queue.name = "HeadFlow.MotionEngineQueue"
    }

    func start() {
        let auth = CMHeadphoneMotionManager.authorizationStatus()
        print("MotionEngine: authorization status = \(auth.rawValue)")

        switch auth {
        case .denied, .restricted:
            print("MotionEngine: motion access denied or restricted")
            return
        default:
            break
        }

        guard manager.isDeviceMotionAvailable else {
            print("MotionEngine: device motion not available (no supported headphones?)")
            return
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

        // Respect user setting.
        guard HeadFlowSettings.isHeadScrollingEnabled else { return }

        let baselineLines = HeadFlowSettings.baseLines()

        // How far from neutral are we?
        guard let neutral = neutralPitchDeg else { return }
        let delta = pitchDeg - neutral

        // If within dead zone, don't scroll.
        if abs(delta) < deadZoneDeg {
            return
        }

        // Clamp tilt to max range and map to [-1, 1].
        let clamped = max(-maxTiltDeg, min(maxTiltDeg, delta))
        let factor = clamped / maxTiltDeg                     // -1 ... 1
        let magnitude = abs(factor)

        // Scale sensitivity by tilt magnitude.
        let lines = Int32(round(Double(baselineLines) * magnitude))
        guard lines > 0 else { return }

        // Decide direction:
        //   tilt head UP (positive delta)  -> scroll UP
        //   tilt head DOWN (negative)      -> scroll DOWN
        if factor > 0 {
            ScrollEngine.scrollUp(lines: lines)
        } else {
            ScrollEngine.scrollDown(lines: lines)
        }
    }

    /// Manually re-calibrate the neutral head position.
    func calibrateNeutral() {
        if let last = lastPitchDeg {
            neutralPitchDeg = last
            print("MotionEngine: manually calibrated neutral pitch = \(last)")
        } else {
            neutralPitchDeg = nil
            print("MotionEngine: no motion samples yet – connect AirPods with head tracking and move your head a bit, then try calibrate again.")
        }
    }

    // MARK: - CMHeadphoneMotionManagerDelegate

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones connected")
        // Reset neutral so new position is calibrated.
        neutralPitchDeg = nil
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones disconnected")
        neutralPitchDeg = nil
    }
}
