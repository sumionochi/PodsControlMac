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
    static let keyAccelerationFactor   = "accelerationFactor"
    static let keyDampingFactor        = "dampingFactor"
    static let keyPauseWhilePointerActive = "pauseWhilePointerActive"
    static let keyPauseWhileTyping        = "pauseWhileTyping"
    static let keyShiftToPauseEnabled     = "shiftToPauseEnabled"
    static let keyGlobalToggleShortcutEnabled        = "globalToggleShortcutEnabled"
    static let keyGlobalCreateProfileShortcutEnabled = "globalCreateProfileShortcutEnabled"
    static let keyGlobalPreferencesShortcutEnabled   = "globalPreferencesShortcutEnabled"
    
    static let keyShortcutToggle      = "shortcutToggle"
    static let keyShortcutProfile     = "shortcutCreateProfile"
    static let keyShortcutPreferences = "shortcutPreferences"
    static let keyShortcutCalibrate   = "shortcutCalibrate"

    static let keyGlobalCalibrateShortcutEnabled = "globalCalibrateShortcutEnabled"
    
    static let keyPauseOnManualScroll       = "pauseOnManualScroll"
    static let keyManualScrollPauseSeconds  = "manualScrollPauseSeconds"
    
    static let keyGestureSettings        = "gestureSettings"
    static let keyGestureTiltThresholdDegrees = "gestureTiltThresholdDegrees"
    static let keyGestureCooldownSeconds      = "gestureCooldownSeconds"
    static let keyHasSeenWelcome      = "hasSeenWelcome"
    
    // MARK: - Defaults

    static let defaultIsHeadScrollingEnabled = true
    static let defaultScrollSensitivity      = 50.0
    static let defaultBaseLines              = 60.0      // max lines per update
    static let defaultDeadZoneDegrees        = 3.0
    static let defaultMaxTiltDegrees         = 25.0
    static let defaultScrollModeRaw          = ScrollMode.continuous.rawValue
    static let defaultLaunchAtLoginModeRaw   = LaunchAtLoginMode.onlyWhenOpening.rawValue
    static let defaultAccelerationFactor = 1.0   // 1.0 = baseline ramp feel
    static let defaultDampingFactor      = 1.0   // 1.0 = baseline slowdown feel
    static let defaultPauseWhilePointerActive = true
    static let defaultPauseWhileTyping        = true
    static let defaultShiftToPauseEnabled     = true
    static let defaultGlobalToggleShortcutEnabled        = true
    static let defaultGlobalCreateProfileShortcutEnabled = true
    static let defaultGlobalPreferencesShortcutEnabled   = true
    static let defaultGestureTiltThresholdDegrees = 20.0   // degrees from neutral
    static let defaultGestureCooldownSeconds      = 0.6
    static let defaultGlobalCalibrateShortcutEnabled = true
    static let defaultHasSeenWelcome  = false
    static let defaultPauseOnManualScroll      = true
    static let defaultManualScrollPauseSeconds = 0.4   // 0.40s pause after manual scroll

    static let defaultToggleShortcut = KeyboardShortcut(
        key: "h",
        modifiers: [.command, .option, .control]   // ⌃⌥⌘H
    )

    static let defaultCreateProfileShortcut = KeyboardShortcut(
        key: "j",
        modifiers: [.command, .option, .control]   // ⌃⌥⌘J
    )

    static let defaultPreferencesShortcut = KeyboardShortcut(
        key: ",",
        modifiers: [.command, .option, .control]   // ⌃⌥⌘,
    )

    static let defaultCalibrateShortcut = KeyboardShortcut(
        key: "k",
        modifiers: [.command, .option, .control]   // ⌃⌥⌘K
    )

    // MARK: - Register defaults

    /// Ensure reasonable defaults exist even if user never opened Preferences.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            keyIsHeadScrollingEnabled:  defaultIsHeadScrollingEnabled,
            keyScrollSensitivity:       defaultScrollSensitivity,
            keyBaseLines:               defaultBaseLines,
            keyDeadZoneDegrees:         defaultDeadZoneDegrees,
            keyMaxTiltDegrees:          defaultMaxTiltDegrees,
            keyScrollMode:              defaultScrollModeRaw,
            keyLaunchAtLoginMode:       defaultLaunchAtLoginModeRaw,
            keyAccelerationFactor:      defaultAccelerationFactor,
            keyDampingFactor:           defaultDampingFactor,
            keyPauseWhilePointerActive: defaultPauseWhilePointerActive,
            keyPauseWhileTyping:        defaultPauseWhileTyping,
            keyShiftToPauseEnabled:     defaultShiftToPauseEnabled,
            keyGlobalToggleShortcutEnabled:        defaultGlobalToggleShortcutEnabled,
            keyGlobalCreateProfileShortcutEnabled: defaultGlobalCreateProfileShortcutEnabled,
            keyGlobalPreferencesShortcutEnabled:   defaultGlobalPreferencesShortcutEnabled,
            keyGlobalCalibrateShortcutEnabled:     defaultGlobalCalibrateShortcutEnabled,
            keyPauseOnManualScroll:      defaultPauseOnManualScroll,
            keyManualScrollPauseSeconds: defaultManualScrollPauseSeconds,
            keyGestureSettings:          Data(),
            keyGestureTiltThresholdDegrees: defaultGestureTiltThresholdDegrees,
            keyGestureCooldownSeconds:      defaultGestureCooldownSeconds,
            keyHasSeenWelcome:      defaultHasSeenWelcome,
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
    
    static var hasSeenWelcome: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyHasSeenWelcome) as? Bool)
            ?? defaultHasSeenWelcome
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyHasSeenWelcome)
        }
    }

    static var accelerationFactor: Double {
        get {
            (UserDefaults.standard.object(forKey: keyAccelerationFactor) as? Double)
            ?? defaultAccelerationFactor
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyAccelerationFactor)
        }
    }

    static var dampingFactor: Double {
        get {
            (UserDefaults.standard.object(forKey: keyDampingFactor) as? Double)
            ?? defaultDampingFactor
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyDampingFactor)
        }
    }
    
    static var gestureTiltThresholdDegrees: Double {
        get {
            (UserDefaults.standard.object(forKey: keyGestureTiltThresholdDegrees) as? Double)
            ?? defaultGestureTiltThresholdDegrees
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyGestureTiltThresholdDegrees)
        }
    }

    static var gestureCooldownSeconds: Double {
        get {
            (UserDefaults.standard.object(forKey: keyGestureCooldownSeconds) as? Double)
            ?? defaultGestureCooldownSeconds
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyGestureCooldownSeconds)
        }
    }

    
    static var pauseWhilePointerActive: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyPauseWhilePointerActive) as? Bool)
            ?? defaultPauseWhilePointerActive
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyPauseWhilePointerActive)
        }
    }

    static var pauseWhileTyping: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyPauseWhileTyping) as? Bool)
            ?? defaultPauseWhileTyping
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyPauseWhileTyping)
        }
    }

    static var shiftToPauseEnabled: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyShiftToPauseEnabled) as? Bool)
            ?? defaultShiftToPauseEnabled
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyShiftToPauseEnabled)
        }
    }
    
    static var globalToggleShortcutEnabled: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyGlobalToggleShortcutEnabled) as? Bool)
            ?? defaultGlobalToggleShortcutEnabled
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyGlobalToggleShortcutEnabled)
        }
    }

    static var globalCreateProfileShortcutEnabled: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyGlobalCreateProfileShortcutEnabled) as? Bool)
            ?? defaultGlobalCreateProfileShortcutEnabled
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyGlobalCreateProfileShortcutEnabled)
        }
    }

    static var globalPreferencesShortcutEnabled: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyGlobalPreferencesShortcutEnabled) as? Bool)
            ?? defaultGlobalPreferencesShortcutEnabled
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyGlobalPreferencesShortcutEnabled)
        }
    }
    
    static var globalCalibrateShortcutEnabled: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyGlobalCalibrateShortcutEnabled) as? Bool)
            ?? defaultGlobalCalibrateShortcutEnabled
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyGlobalCalibrateShortcutEnabled)
        }
    }
    
    static var pauseOnManualScroll: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyPauseOnManualScroll) as? Bool)
            ?? defaultPauseOnManualScroll
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyPauseOnManualScroll)
        }
    }

    static var manualScrollPauseSeconds: Double {
        get {
            (UserDefaults.standard.object(forKey: keyManualScrollPauseSeconds) as? Double)
            ?? defaultManualScrollPauseSeconds
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyManualScrollPauseSeconds)
        }
    }
    
    // MARK: - Gesture settings (mappings + custom shortcut bank)

    static var gestureSettings: GestureSettings {
        get {
            let defaults = UserDefaults.standard
            guard let data = defaults.data(forKey: keyGestureSettings),
                  !data.isEmpty else {
                // If nothing stored yet, return a sensible default config.
                return defaultGestureSettings()
            }

            do {
                let decoded = try JSONDecoder().decode(GestureSettings.self, from: data)
                return decoded
            } catch {
                print("HeadFlowSettings: failed to decode GestureSettings: \(error)")
                return defaultGestureSettings()
            }
        }
        set {
            let defaults = UserDefaults.standard
            do {
                let data = try JSONEncoder().encode(newValue)
                defaults.set(data, forKey: keyGestureSettings)
            } catch {
                print("HeadFlowSettings: failed to encode GestureSettings: \(error)")
            }
        }
    }

    /// Provide initial mappings & an empty custom shortcut bank.
    private static func defaultGestureSettings() -> GestureSettings {
        // By default, no gestures do anything until user configures them.
        var mappings: [GestureMapping] = []

        // HeadFlow ON: 3 gestures
        for gesture in [GestureType.tiltLeft, .tiltRight, .shake] {
            mappings.append(GestureMapping(
                context: .headFlowOn,
                gesture: gesture,
                action: .none
            ))
        }

        // HeadFlow OFF: 5 gestures
        for gesture in GestureType.allCases {
            mappings.append(GestureMapping(
                context: .headFlowOff,
                gesture: gesture,
                action: .none
            ))
        }

        return GestureSettings(mappings: mappings, customShortcuts: [])
    }

    // MARK: - Helpers used by MotionEngine, etc.
    
    private static func loadShortcut(forKey key: String,
                                     default defaultShortcut: KeyboardShortcut) -> KeyboardShortcut {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            return decoded
        }
        return defaultShortcut
    }

    private static func saveShortcut(_ shortcut: KeyboardShortcut, forKey key: String) {
        if let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static var shortcutToggle: KeyboardShortcut {
        get { loadShortcut(forKey: keyShortcutToggle, default: defaultToggleShortcut) }
        set { saveShortcut(newValue, forKey: keyShortcutToggle) }
    }

    static var shortcutCreateProfile: KeyboardShortcut {
        get { loadShortcut(forKey: keyShortcutProfile, default: defaultCreateProfileShortcut) }
        set { saveShortcut(newValue, forKey: keyShortcutProfile) }
    }

    static var shortcutPreferences: KeyboardShortcut {
        get { loadShortcut(forKey: keyShortcutPreferences, default: defaultPreferencesShortcut) }
        set { saveShortcut(newValue, forKey: keyShortcutPreferences) }
    }

    static var shortcutCalibrate: KeyboardShortcut {
        get { loadShortcut(forKey: keyShortcutCalibrate, default: defaultCalibrateShortcut) }
        set { saveShortcut(newValue, forKey: keyShortcutCalibrate) }
    }

    /// Integer version of baseLinesValue for scroll engine.
    static func baseLines() -> Int32 {
        Int32(baseLinesValue.rounded())
    }
}
