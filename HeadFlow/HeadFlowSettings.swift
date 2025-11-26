//HeadFlowSettings
import Foundation
import AppKit
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
    
    // NEW KEYS
    static let keyShortcutCycleModes  = "shortcutCycleModes"
    static let keyGlobalCycleModesShortcutEnabled = "globalCycleModesShortcutEnabled"

    static let keyGlobalCalibrateShortcutEnabled = "globalCalibrateShortcutEnabled"
    
    static let keyPauseOnManualScroll       = "pauseOnManualScroll"
    static let keyManualScrollPauseSeconds  = "manualScrollPauseSeconds"
    
    static let keyGestureSettings        = "gestureSettings"
    static let keyGestureTiltThresholdDegrees = "gestureTiltThresholdDegrees"
    static let keyGestureCooldownSeconds      = "gestureCooldownSeconds"
    static let keyHasSeenWelcome      = "hasSeenWelcome"
    
    // Cursor control settings
    static let keyCursorSpeed                = "cursorSpeed"
    static let keyCursorDeadZone             = "cursorDeadZone"
    static let keyCursorSmoothing            = "cursorSmoothing"
    static let keyCursorSingleClickYawDeg    = "cursorSingleClickYawDegrees"
    static let keyCursorDoubleClickYawDeg    = "cursorDoubleClickYawDegrees"
    static let keyCursorClickCooldown        = "cursorClickCooldown"

    static let keyCursorClickModifiersRaw       = "cursorClickModifiersRaw"
    static let keyCursorDragExtraModifiersRaw   = "cursorDragExtraModifiersRaw"
    
    static let keyDictationEnabled = "dictationEnabled"
    static let keyDictationPausesHeadFlow   = "dictationPausesHeadFlow"
    static let keyGlobalDictationHUDShortcutEnabled = "globalDictationHUDShortcutEnabled"
    static let keyGlobalDictationMicShortcutEnabled = "globalDictationMicShortcutEnabled"

    static let keyShortcutDictationHUD = "shortcutDictationHUD"
    static let keyShortcutDictationMic = "shortcutDictationMic"
    // MARK: - Dictation

    static let keyDictationAutoCommitDelaySeconds = "headflow.dictation.autoCommitDelaySeconds"

    
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
    static let defaultGestureTiltThresholdDegrees = 10.0   // degrees from neutral
    static let defaultGestureCooldownSeconds      = 0.6
    static let defaultGlobalCalibrateShortcutEnabled = true
    static let defaultHasSeenWelcome  = false
    static let defaultPauseOnManualScroll      = true
    static let defaultManualScrollPauseSeconds = 0.4   // 0.40s pause after manual scroll
    // Cursor control defaults
    static let defaultCursorSpeed: Double             = 2.5
    static let defaultCursorDeadZone: Double          = 0.3
    static let defaultCursorSmoothing: Double         = 0.3
    static let defaultCursorSingleClickYawDeg: Double = 10.0
    static let defaultCursorDoubleClickYawDeg: Double = 20.0
    static let defaultCursorClickCooldown: Double     = 0.5
    static let defaultDictationAutoCommitDelaySeconds: Double = 1.5

    static let defaultCursorClickModifiersRaw: Int =
        Int(NSEvent.ModifierFlags.command.rawValue)

    static let defaultCursorDragExtraModifiersRaw: Int =
        Int(NSEvent.ModifierFlags.control.rawValue)
    
    // NEW DEFAULTS
    static let defaultGlobalCycleModesShortcutEnabled = true

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
    
    // Default: Control + Option + Command + .
    static let defaultCycleModesShortcut = KeyboardShortcut(
        key: ".",
        modifiers: [.command, .option, .control]   // ⌃⌥⌘.
    )
    
    static let defaultDictationEnabled = true
    static let defaultDictationPausesHeadFlow = true

    static let defaultGlobalDictationHUDShortcutEnabled = true
    static let defaultGlobalDictationMicShortcutEnabled = true

    // HUD toggle: ⌃⌥⌘ ;
    static let defaultDictationHUDShortcut = KeyboardShortcut(
        key: ";",
        modifiers: [.command, .option, .control]
    )

    // Mic start/stop: ⌃⌥⌘ '
    static let defaultDictationMicShortcut = KeyboardShortcut(
        key: "'",
        modifiers: [.command, .option, .control]
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
            // Cursor control
            keyCursorSpeed:                defaultCursorSpeed,
            keyCursorDeadZone:             defaultCursorDeadZone,
            keyCursorSmoothing:            defaultCursorSmoothing,
            keyCursorSingleClickYawDeg:    defaultCursorSingleClickYawDeg,
            keyCursorDoubleClickYawDeg:    defaultCursorDoubleClickYawDeg,
            keyCursorClickCooldown:        defaultCursorClickCooldown,
            keyCursorClickModifiersRaw:       defaultCursorClickModifiersRaw,
            keyCursorDragExtraModifiersRaw:   defaultCursorDragExtraModifiersRaw,
            
            keyDictationEnabled:                 defaultDictationEnabled,
            keyGlobalDictationHUDShortcutEnabled: defaultGlobalDictationHUDShortcutEnabled,
            keyGlobalDictationMicShortcutEnabled: defaultGlobalDictationMicShortcutEnabled,
            keyDictationPausesHeadFlow: defaultDictationPausesHeadFlow,
            // Register new keys
            keyGlobalCycleModesShortcutEnabled: defaultGlobalCycleModesShortcutEnabled
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
    
    static var dictationAutoCommitDelaySeconds: Double {
        get {
            let value = UserDefaults.standard.double(forKey: keyDictationAutoCommitDelaySeconds)
            // .double(forKey:) returns 0 when not set — treat that as “use default”.
            return value == 0 ? defaultDictationAutoCommitDelaySeconds : value
        }
        set {
            // Clamp to a sensible range: 0.5–10 seconds of silence
            let clamped = max(0.5, min(newValue, 10.0))
            UserDefaults.standard.set(clamped, forKey: keyDictationAutoCommitDelaySeconds)
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
    
    // MARK: - Dictation

    static var dictationEnabled: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyDictationEnabled) as? Bool)
            ?? defaultDictationEnabled
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyDictationEnabled)
        }
    }

    static var dictationPausesHeadFlow: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyDictationPausesHeadFlow) as? Bool)
            ?? defaultDictationPausesHeadFlow
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyDictationPausesHeadFlow)
        }
    }

    static var globalDictationHUDShortcutEnabled: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyGlobalDictationHUDShortcutEnabled) as? Bool)
            ?? defaultGlobalDictationHUDShortcutEnabled
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyGlobalDictationHUDShortcutEnabled)
        }
    }

    static var globalDictationMicShortcutEnabled: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyGlobalDictationMicShortcutEnabled) as? Bool)
            ?? defaultGlobalDictationMicShortcutEnabled
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyGlobalDictationMicShortcutEnabled)
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
    
    static var globalCycleModesShortcutEnabled: Bool {
        get {
            (UserDefaults.standard.object(forKey: keyGlobalCycleModesShortcutEnabled) as? Bool)
            ?? defaultGlobalCycleModesShortcutEnabled
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyGlobalCycleModesShortcutEnabled)
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
    
    // MARK: - Cursor control

    static var cursorSpeed: Double {
        get {
            (UserDefaults.standard.object(forKey: keyCursorSpeed) as? Double)
            ?? defaultCursorSpeed
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyCursorSpeed)
        }
    }

    static var cursorDeadZone: Double {
        get {
            (UserDefaults.standard.object(forKey: keyCursorDeadZone) as? Double)
            ?? defaultCursorDeadZone
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyCursorDeadZone)
        }
    }

    static var cursorSmoothing: Double {
        get {
            (UserDefaults.standard.object(forKey: keyCursorSmoothing) as? Double)
            ?? defaultCursorSmoothing
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyCursorSmoothing)
        }
    }

    static var cursorSingleClickYawDegrees: Double {
        get {
            (UserDefaults.standard.object(forKey: keyCursorSingleClickYawDeg) as? Double)
            ?? defaultCursorSingleClickYawDeg
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyCursorSingleClickYawDeg)
        }
    }

    static var cursorDoubleClickYawDegrees: Double {
        get {
            (UserDefaults.standard.object(forKey: keyCursorDoubleClickYawDeg) as? Double)
            ?? defaultCursorDoubleClickYawDeg
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyCursorDoubleClickYawDeg)
        }
    }

    static var cursorClickCooldown: Double {
        get {
            (UserDefaults.standard.object(forKey: keyCursorClickCooldown) as? Double)
            ?? defaultCursorClickCooldown
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyCursorClickCooldown)
        }
    }

    private static let allowedCursorFlags: NSEvent.ModifierFlags =
        [.command, .option, .control, .shift]

    static var cursorClickModifiers: NSEvent.ModifierFlags {
        get {
            let raw = (UserDefaults.standard.object(forKey: keyCursorClickModifiersRaw) as? Int)
                      ?? defaultCursorClickModifiersRaw
            return NSEvent.ModifierFlags(rawValue: UInt(raw))
                .intersection(allowedCursorFlags)
        }
        set {
            let filtered = newValue.intersection(allowedCursorFlags)
            guard !filtered.isEmpty else { return }    // don't allow “no modifier”
            UserDefaults.standard.set(Int(filtered.rawValue), forKey: keyCursorClickModifiersRaw)
        }
    }

    static var cursorDragExtraModifiers: NSEvent.ModifierFlags {
        get {
            let raw = (UserDefaults.standard.object(forKey: keyCursorDragExtraModifiersRaw) as? Int)
                      ?? defaultCursorDragExtraModifiersRaw
            return NSEvent.ModifierFlags(rawValue: UInt(raw))
                .intersection(allowedCursorFlags)
        }
        set {
            let filtered = newValue.intersection(allowedCursorFlags)
            UserDefaults.standard.set(Int(filtered.rawValue), forKey: keyCursorDragExtraModifiersRaw)
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

    private static func defaultGestureSettings() -> GestureSettings {
        var mappings: [GestureMapping] = []
        for gesture in [GestureType.tiltLeft, .tiltRight, .shake] {
            mappings.append(GestureMapping(
                context: .headFlowOn,
                gesture: gesture,
                action: .none
            ))
        }
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
    
    static var shortcutDictationHUD: KeyboardShortcut {
        get { loadShortcut(forKey: keyShortcutDictationHUD,
                           default: defaultDictationHUDShortcut) }
        set { saveShortcut(newValue, forKey: keyShortcutDictationHUD) }
    }

    static var shortcutDictationMic: KeyboardShortcut {
        get { loadShortcut(forKey: keyShortcutDictationMic,
                           default: defaultDictationMicShortcut) }
        set { saveShortcut(newValue, forKey: keyShortcutDictationMic) }
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
    
    static var shortcutCycleModes: KeyboardShortcut {
        get { loadShortcut(forKey: keyShortcutCycleModes, default: defaultCycleModesShortcut) }
        set { saveShortcut(newValue, forKey: keyShortcutCycleModes) }
    }

    static func baseLines() -> Int32 {
        Int32(baseLinesValue.rounded())
    }
}
