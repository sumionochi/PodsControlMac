import Foundation

/// Central place for user defaults keys / default values.
enum HeadFlowSettings {
    // MARK: - Keys

    static let keyIsHeadScrollingEnabled = "isHeadScrollingEnabled"
    static let keyScrollSensitivity      = "scrollSensitivity"
    static let keyBaseLines              = "baseLines"
    static let keyDeadZoneDegrees        = "deadZoneDegrees"
    static let keyMaxTiltDegrees         = "maxTiltDegrees"
    static let keyScrollMode             = "scrollModeRaw"
    static let keyLaunchAtLoginMode      = "launchAtLoginMode"

    // MARK: - Defaults

    static let defaultIsHeadScrollingEnabled = true
    static let defaultScrollSensitivity      = 50.0
    static let defaultBaseLines              = 60.0      // max lines per update
    static let defaultDeadZoneDegrees        = 3.0
    static let defaultMaxTiltDegrees         = 25.0
    static let defaultScrollModeRaw          = ScrollMode.continuous.rawValue
    static let defaultLaunchAtLoginModeRaw   = LaunchAtLoginMode.onlyWhenOpening.rawValue

    // MARK: - Register defaults

    /// Ensure reasonable defaults exist even if user never opened Preferences.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            keyIsHeadScrollingEnabled: defaultIsHeadScrollingEnabled,
            keyScrollSensitivity:      defaultScrollSensitivity,
            keyBaseLines:              defaultBaseLines,
            keyDeadZoneDegrees:        defaultDeadZoneDegrees,
            keyMaxTiltDegrees:         defaultMaxTiltDegrees,
            keyScrollMode:             defaultScrollModeRaw,
            keyLaunchAtLoginMode:      defaultLaunchAtLoginModeRaw
        ])
    }

    // MARK: - Global settings accessors

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

    static var baseLinesValue: Double {
        get {
            (UserDefaults.standard.object(forKey: keyBaseLines) as? Double)
            ?? defaultBaseLines
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyBaseLines)
        }
    }

    static var deadZoneDegrees: Double {
        get {
            (UserDefaults.standard.object(forKey: keyDeadZoneDegrees) as? Double)
            ?? defaultDeadZoneDegrees
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyDeadZoneDegrees)
        }
    }

    static var maxTiltDegrees: Double {
        get {
            (UserDefaults.standard.object(forKey: keyMaxTiltDegrees) as? Double)
            ?? defaultMaxTiltDegrees
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyMaxTiltDegrees)
        }
    }

    static var scrollModeRaw: Int {
        get {
            (UserDefaults.standard.object(forKey: keyScrollMode) as? Int)
            ?? defaultScrollModeRaw
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyScrollMode)
        }
    }

    static var scrollMode: ScrollMode {
        get { ScrollMode(rawValue: scrollModeRaw) ?? .continuous }
        set { scrollModeRaw = newValue.rawValue }
    }

    static var launchAtLoginMode: LaunchAtLoginMode {
        get {
            let raw = (UserDefaults.standard.object(forKey: keyLaunchAtLoginMode) as? Int)
                      ?? defaultLaunchAtLoginModeRaw
            return LaunchAtLoginMode(rawValue: raw) ?? .onlyWhenOpening
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: keyLaunchAtLoginMode)
        }
    }

    // MARK: - Helpers used by MotionEngine, etc.

    /// Integer version of baseLinesValue for scroll engine.
    static func baseLines() -> Int32 {
        Int32(baseLinesValue.rounded())
    }
}
