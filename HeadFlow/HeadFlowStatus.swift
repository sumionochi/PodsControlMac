import Foundation
import CoreMotion
import AppKit
import CoreAudio

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
    @Published var frontmostAppName: String = "Unknown"
    @Published var frontmostBundleIdentifier: String? = nil


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
    
    // MARK: - Frontmost app tracking

    func startObservingFrontmostApp() {
        updateFrontmostAppImmediately()

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateFrontmostAppImmediately()
        }
    }

    // MARK: - Audio device observation (CoreAudio)

    /// Call once on app launch to track default output device changes.
    func startObservingAudioDevice() {
        guard !didInstallAudioListener else { return }

        // Initial fetch
        refreshActiveAudioDeviceName()

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectAddPropertyListenerBlock(
            systemObjectID,
            &address,
            DispatchQueue.global(qos: .utility)
        ) { [weak self] _, _ in
            self?.refreshActiveAudioDeviceName()
        }

        if status != noErr {
            print("HeadFlowStatus: failed to add audio device listener, status = \(status)")
        } else {
            didInstallAudioListener = true
        }
    }

    /// Re-reads CoreAudio default output device name and pushes to @Published property.
    private func refreshActiveAudioDeviceName() {
        let name = AudioDeviceInfo.defaultOutputDeviceName() ?? "Unknown device"

        DispatchQueue.main.async {
            self.audioDeviceName = name
        }
    }

    
    private func updateFrontmostAppImmediately() {
        let app = NSWorkspace.shared.frontmostApplication
        DispatchQueue.main.async {
            self.frontmostAppName = app?.localizedName ?? "Unknown"
            self.frontmostBundleIdentifier = app?.bundleIdentifier
        }
    }

    // MARK: - Summary helpers
    var currentProfileSummary: String {
        guard let bundleID = frontmostBundleIdentifier else {
            return "Using global settings (no active app)"
        }

        if ProfileManager.shared.profile(for: bundleID) != nil {
            return "Currently focused on \(frontmostAppName) (using per-app profile)"
        } else {
            return "Currently focused on \(frontmostAppName) (using global settings)"
        }
    }
    
    // MARK: - Device summary & icon

    /// Human-readable summary for Preferences / live panel.
    var trackingDeviceSummary: String {
        switch headphones {
        case .connected:
            if audioDeviceName.isEmpty || audioDeviceName == "Unknown device" {
                return "Tracking from compatible headphones"
            } else {
                return "Tracking from \(audioDeviceName)"
            }
        case .notConnected, .notSupported:
            return "No supported headphones connected"
        case .unknown:
            return "Headphone status unknown"
        }
    }

    /// Summary variant suitable for the status bar menu item.
    var trackingDeviceMenuSummary: String {
        switch headphones {
        case .connected:
            if audioDeviceName.isEmpty || audioDeviceName == "Unknown device" {
                return "Head tracking: Connected"
            } else {
                return "Head tracking: \(audioDeviceName)"
            }
        case .notConnected, .notSupported:
            return "Head tracking: Not connected"
        case .unknown:
            return "Head tracking: Unknown"
        }
    }

    /// Pick an SF Symbol that roughly matches the current device for a nice UI icon.
    ///
    /// Requires macOS 11+, which is fine since HeadFlow already targets 14.
    var trackingDeviceSymbolName: String {
        guard headphones == .connected else {
            return "headphones"
        }

        let lower = audioDeviceName.lowercased()

        // Very simple heuristics based on the audio device name.
        if lower.contains("airpods") {
            return "airpods.pro"
        }

        if lower.contains("beats") {
            // We could refine for Studio Buds / Fit Pro, but a generic Beats icon is fine.
            return "beats.earphones"
        }

        if lower.contains("speaker") || lower.contains("display audio") {
            return "speaker.wave.2.fill"
        }

        // Fallback
        return "headphones"
    }
    
    // MARK: - Audio device tracking for live panel / menu

    /// Current default output device name (e.g. "Mito’s AirPods Pro").
    @Published var audioDeviceName: String = "Unknown device"

    /// Internal flag so we only install the CoreAudio listener once.
    private var didInstallAudioListener = false

}
