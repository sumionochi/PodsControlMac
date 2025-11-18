import Foundation

/// Central place for user defaults keys / default values.
enum HeadFlowSettings {
    static let keyIsHeadScrollingEnabled = "isHeadScrollingEnabled"
    static let keyScrollSensitivity = "scrollSensitivity"

    /// Ensure reasonable defaults exist even if user never opened Preferences.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            keyIsHeadScrollingEnabled: true,
            keyScrollSensitivity: 50.0
        ])
    }

    static var isHeadScrollingEnabled: Bool {
        get {
            // Use `?? true` so if something goes wrong we default to ON.
            (UserDefaults.standard.object(forKey: keyIsHeadScrollingEnabled) as? Bool) ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyIsHeadScrollingEnabled)
        }
    }

    static var scrollSensitivity: Double {
        get {
            (UserDefaults.standard.object(forKey: keyScrollSensitivity) as? Double) ?? 50.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyScrollSensitivity)
        }
    }

    /// Same mapping as in PreferencesView: 0–100 → ~1–10 lines.
    static func baseLines() -> Int32 {
        let clamped = max(0.0, min(100.0, scrollSensitivity))
        let normalized = clamped / 100.0
        let lines = 1 + normalized * 9.0
        return Int32(lines.rounded())
    }
}
