import Foundation
import CoreMotion

/// Handles motion updates from compatible headphones (AirPods, Beats).
@available(macOS 14.0, *)
final class MotionEngine: NSObject, CMHeadphoneMotionManagerDelegate {

    private let manager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()

    override init() {
        super.init()
        manager.delegate = self
        queue.name = "HeadFlow.MotionEngineQueue"
    }

    /// Starts listening for headphone motion and logs pitch/roll.
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

    /// Stops motion updates if they are running.
    func stop() {
        guard manager.isDeviceMotionActive else { return }
        manager.stopDeviceMotionUpdates()
        print("MotionEngine: stopped device motion updates")
    }

    /// Called on our background queue whenever new motion data arrives.
    private func handle(motion: CMDeviceMotion) {
        let attitude = motion.attitude

        let pitchDeg = attitude.pitch * 180.0 / .pi
        let rollDeg  = attitude.roll  * 180.0 / .pi
        let yawDeg   = attitude.yaw   * 180.0 / .pi

        // Basic logging for now; later we'll map this to scroll speed.
        print(String(
            format: "MotionEngine: pitch=%.1f°, roll=%.1f°, yaw=%.1f°",
            pitchDeg, rollDeg, yawDeg
        ))
    }

    // MARK: - CMHeadphoneMotionManagerDelegate

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones connected")
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("MotionEngine: headphones disconnected")
    }
}
