import Foundation
import CoreMotion
import AppKit

/// Shared status object that tracks permissions and hardware state
/// so the UI can show clear messages to the user.
final class HeadFlowStatus: ObservableObject {

    static let shared = HeadFlowStatus()

    private init() {}

    // MARK: - Enums

    enum MotionAuth {
        case unknown
        case notDetermined
        case denied
        case restricted
        case authorized
    }

    enum HeadphoneStatus {
        case unknown
        case notSupported
        case notConnected
        case connected
    }

    enum AccessibilityStatus {
        case unknown
        case disabled
        case enabled
    }

    // MARK: - Published state

    @Published var motionAuth: MotionAuth = .unknown
    @Published var headphones: HeadphoneStatus = .unknown
    @Published var accessibility: AccessibilityStatus = .unknown

    // MARK: - Updates

    /// Use CMAuthorizationStatus (from CoreMotion), not a nested type.
    func updateMotionAuthorization(_ status: CMAuthorizationStatus) {
        let mapped: MotionAuth
        switch status {
        case .notDetermined:
            mapped = .notDetermined
        case .restricted:
            mapped = .restricted
        case .denied:
            mapped = .denied
        case .authorized:
            mapped = .authorized
        @unknown default:
            mapped = .unknown
        }

        DispatchQueue.main.async {
            self.motionAuth = mapped
        }
    }

    func setHeadphonesStatus(_ status: HeadphoneStatus) {
        DispatchQueue.main.async {
            self.headphones = status
        }
    }

    func refreshAccessibilityStatus() {
        // AXIsProcessTrusted() returns current Accessibility permission for this app.
        let trusted = AXIsProcessTrusted()
        let mapped: AccessibilityStatus = trusted ? .enabled : .disabled

        DispatchQueue.main.async {
            self.accessibility = mapped
        }
    }

    /// Convenience: refreshes everything we can query synchronously.
    func refreshAll() {
        refreshAccessibilityStatus()
        let auth = CMHeadphoneMotionManager.authorizationStatus()
        updateMotionAuthorization(auth)
        // Headphone connection is event-driven via delegate; nothing to refresh here.
    }

    // MARK: - UI descriptions

    var motionAuthDescription: String {
        switch motionAuth {
        case .unknown:       return "Unknown"
        case .notDetermined: return "Not determined"
        case .denied:        return "Denied"
        case .restricted:    return "Restricted"
        case .authorized:    return "Authorized"
        }
    }

    var headphoneDescription: String {
        switch headphones {
        case .unknown:       return "Unknown"
        case .notSupported:  return "No supported headphones"
        case .notConnected:  return "Not connected"
        case .connected:     return "Connected"
        }
    }

    var accessibilityDescription: String {
        switch accessibility {
        case .unknown:   return "Unknown"
        case .disabled:  return "Disabled"
        case .enabled:   return "Enabled"
        }
    }

    /// Simple overall summary useful for the UI if you ever want it.
    var overallSummary: String {
        if motionAuth == .authorized,
           accessibility == .enabled,
           headphones == .connected {
            return "Ready"
        }

        return "Needs setup"
    }
}
