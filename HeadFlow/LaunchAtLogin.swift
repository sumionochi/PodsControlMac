import Foundation
import ServiceManagement

/// User-facing choices for "Launch at Login".
enum LaunchAtLoginMode: Int, CaseIterable, Identifiable {
    /// Register HeadFlow as a login item (runs after user logs in).
    case always = 0

    /// Do not register as a login item; HeadFlow only runs when opened manually.
    case onlyWhenOpening = 1

    var id: Int { rawValue }

    /// Title used in the status bar submenu.
    var menuTitle: String {
        switch self {
        case .always:
            return "Always"
        case .onlyWhenOpening:
            return "Only when I open HeadFlow"
        }
    }
}
//LaunchAtLoginController
/// Syncs our launch-at-login setting with macOS using SMAppService (macOS 13+).
enum LaunchAtLoginController {

    /// Apply the current HeadFlowSettings.launchAtLoginMode to the OS.
    static func syncFromSettingsToSystem() {
        guard #available(macOS 13.0, *) else {
            // On older macOS versions we just do nothing; setting will be ignored.
            return
        }

        let mode = HeadFlowSettings.launchAtLoginMode

        switch mode {
        case .always:
            // Register main app as a login item.
            // macOS will show the “Login Item Added” notification and allow
            // the user to manage it in System Settings. :contentReference[oaicite:0]{index=0}
            try? SMAppService.mainApp.register()

        case .onlyWhenOpening:
            // Remove the login item registration if it exists.
            try? SMAppService.mainApp.unregister()
        }
    }
}
