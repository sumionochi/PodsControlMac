import Foundation

/// Central place for user defaults keys / default values.
enum HeadFlowSettings {
    // Keys
    static let keyIsHeadScrollingEnabled = "isHeadScrollingEnabled"
    static let keyScrollSensitivity      = "scrollSensitivity"
    static let keyDeadZoneDegrees        = "deadZoneDegrees"
    static let keyMaxTiltDegrees         = "maxTiltDegrees"
    static let keyBaseLines              = "baseLines"
    static let keyScrollMode             = "scrollMode"

    // Defaults
    static let defaultIsHeadScrollingEnabled: Bool   = true
    static let defaultScrollSensitivity: Double      = 50.0   // 0–100
    static let defaultDeadZoneDegrees: Double        = 3.0    // degrees
    static let defaultMaxTiltDegrees: Double         = 25.0   // degrees
    static let defaultBaseLines: Double              = 5.0    // 1–20 recommended
    static let defaultScrollModeRaw: Int             = ScrollMode.continuous.rawValue

    /// Ensure reasonable defaults exist even if user never opened Preferences.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            keyIsHeadScrollingEnabled: defaultIsHeadScrollingEnabled,
            keyScrollSensitivity:      defaultScrollSensitivity,
            keyDeadZoneDegrees:        defaultDeadZoneDegrees,
            keyMaxTiltDegrees:         defaultMaxTiltDegrees,
            keyBaseLines:              defaultBaseLines,
            keyScrollMode:             defaultScrollModeRaw
        ])
    }

    static var isHeadScrollingEnabled: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyIsHeadScrollingEnabled) as? Bool)
            ?? defaultIsHeadScrollingEnabled
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyIsHeadScrollingEnabled)
        }
    }

    static var scrollSensitivity: Double {
        get {
            (UserDefaults.standard.object(forKey: keyScrollSensitivity) as? Double)
            ?? defaultScrollSensitivity
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyScrollSensitivity)
        }
    }

    static var deadZoneDegrees: Double {
        get {
            if UserDefaults.standard.object(forKey: keyDeadZoneDegrees) == nil {
                return defaultDeadZoneDegrees
            }
            return UserDefaults.standard.double(forKey: keyDeadZoneDegrees)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyDeadZoneDegrees)
        }
    }

    static var maxTiltDegrees: Double {
        get {
            if UserDefaults.standard.object(forKey: keyMaxTiltDegrees) == nil {
                return defaultMaxTiltDegrees
            }
            return UserDefaults.standard.double(forKey: keyMaxTiltDegrees)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyMaxTiltDegrees)
        }
    }

    /// Raw base lines as stored (double, slider)
    static var baseLinesRaw: Double {
        get {
            if UserDefaults.standard.object(forKey: keyBaseLines) == nil {
                return defaultBaseLines
            }
            return UserDefaults.standard.double(forKey: keyBaseLines)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyBaseLines)
        }
    }

    /// Base scroll lines per update, clamped to 1–20.
    static func baseLines() -> Int32 {
        let clamped = max(1.0, min(20.0, baseLinesRaw))
        return Int32(clamped.rounded())
    }

    static var scrollMode: ScrollMode {
        get {
            let raw = UserDefaults.standard.object(forKey: keyScrollMode) as? Int
                ?? defaultScrollModeRaw
            return ScrollMode(rawValue: raw) ?? .continuous
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: keyScrollMode)
        }
    }
}
