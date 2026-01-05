// PreferencesView - Improved UI
// A comprehensive preferences interface for PodsControlMac
// with better organization, accessibility, and user guidance

import SwiftUI
import AppKit

// MARK: - Design System

/// Centralized design constants for consistent UI
private enum Design {
    // Spacing
    static let spacing: CGFloat = 20
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 16
    static let itemSpacing: CGFloat = 12
    
    // Corners & Shadows
    static let cardRadius: CGFloat = 14
    static let buttonRadius: CGFloat = 8
    static let shadowOpacity: Double = 0.08
    static let shadowRadius: CGFloat = 10
    
    // Icons
    static let iconSize: CGFloat = 16
    static let headerIconSize: CGFloat = 20
    
    // Animation
    static let springResponse: Double = 0.4
    static let springDamping: Double = 0.75
}

// MARK: - Tab Definition

enum PreferencesTab: String, CaseIterable, Identifiable {
    case setup = "Setup"
    case controls = "Controls"
    case gestures = "Gestures"
    case voice = "Voice"
    case apps = "Apps"
    case shortcuts = "Shortcuts"
    case license = "License"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .setup: return "checkmark.seal"
        case .controls: return "slider.horizontal.3"
        case .gestures: return "hand.point.up.left"
        case .voice: return "waveform"
        case .apps: return "square.grid.2x2"
        case .shortcuts: return "keyboard"
        case .license: return "lock.open"
        }
    }
    
    var description: String {
        switch self {
        case .setup: return "Connection status and permissions"
        case .controls: return "Scrolling and cursor settings"
        case .gestures: return "Head tilt actions"
        case .voice: return "Dictation and voice commands"
        case .apps: return "Per-app customization"
        case .shortcuts: return "Keyboard shortcuts"
        case .license: return "Manage your license"
        }
    }
}

// MARK: - Main Preferences View

struct PreferencesView: View {
    // MARK: - Observed State
    
    @ObservedObject private var status: HeadFlowStatus
    @ObservedObject private var headphones = HeadphoneDeviceState.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    // MARK: - AppStorage Properties (Global Settings)
    
    // Basic Scrolling
    @AppStorage(HeadFlowSettings.keyIsHeadScrollingEnabled)
    private var isHeadScrollingEnabled: Bool = HeadFlowSettings.defaultIsHeadScrollingEnabled
    
    @AppStorage(HeadFlowSettings.keyScrollSensitivity)
    private var scrollSensitivity: Double = HeadFlowSettings.defaultScrollSensitivity
    
    @AppStorage(HeadFlowSettings.keyBaseLines)
    private var baseLines: Double = HeadFlowSettings.defaultBaseLines
    
    @AppStorage(HeadFlowSettings.keyScrollMode)
    private var scrollModeRaw: Int = HeadFlowSettings.defaultScrollModeRaw
    
    // Gesture Settings
    @AppStorage(HeadFlowSettings.keyGestureTiltThresholdDegrees)
    private var gestureTiltThresholdDegrees: Double = HeadFlowSettings.defaultGestureTiltThresholdDegrees
    
    @AppStorage(HeadFlowSettings.keyGestureCooldownSeconds)
    private var gestureCooldownSeconds: Double = HeadFlowSettings.defaultGestureCooldownSeconds
    
    // Dictation Settings
    @AppStorage(HeadFlowSettings.keyDictationPausesHeadFlow)
    private var dictationPausesHeadFlow: Bool = HeadFlowSettings.defaultDictationPausesHeadFlow
    
    @AppStorage(HeadFlowSettings.keyDictationAutoCommitEnabled)
    private var dictationAutoCommitEnabled: Bool = HeadFlowSettings.defaultDictationAutoCommitEnabled
    
    @AppStorage(HeadFlowSettings.keyDictationAutoCommitDelaySeconds)
    private var dictationAutoCommitDelaySeconds: Double = HeadFlowSettings.defaultDictationAutoCommitDelaySeconds
    
    // Safety & Pausing
    @AppStorage(HeadFlowSettings.keyPauseWhilePointerActive)
    private var pauseWhilePointerActive: Bool = HeadFlowSettings.defaultPauseWhilePointerActive
    
    @AppStorage(HeadFlowSettings.keyPauseWhileTyping)
    private var pauseWhileTyping: Bool = HeadFlowSettings.defaultPauseWhileTyping
    
    @AppStorage(HeadFlowSettings.keyShiftToPauseEnabled)
    private var shiftToPauseEnabled: Bool = HeadFlowSettings.defaultShiftToPauseEnabled
    
    @AppStorage(HeadFlowSettings.keyPauseOnManualScroll)
    private var pauseOnManualScroll: Bool = HeadFlowSettings.defaultPauseOnManualScroll
    
    @AppStorage(HeadFlowSettings.keyManualScrollPauseSeconds)
    private var manualScrollPauseSeconds: Double = HeadFlowSettings.defaultManualScrollPauseSeconds
    
    // Advanced Tuning
    @AppStorage(HeadFlowSettings.keyDeadZoneDegrees)
    private var deadZoneDegrees: Double = HeadFlowSettings.defaultDeadZoneDegrees
    
    @AppStorage(HeadFlowSettings.keyMaxTiltDegrees)
    private var maxTiltDegrees: Double = HeadFlowSettings.defaultMaxTiltDegrees
    
    @AppStorage(HeadFlowSettings.keyAccelerationFactor)
    private var accelerationFactor: Double = HeadFlowSettings.defaultAccelerationFactor
    
    @AppStorage(HeadFlowSettings.keyDampingFactor)
    private var dampingFactor: Double = HeadFlowSettings.defaultDampingFactor
    
    // Cursor Control
    @AppStorage(HeadFlowSettings.keyCursorSpeed)
    private var cursorSpeed = HeadFlowSettings.defaultCursorSpeed
    
    @AppStorage(HeadFlowSettings.keyCursorDeadZone)
    private var cursorDeadZone = HeadFlowSettings.defaultCursorDeadZone
    
    @AppStorage(HeadFlowSettings.keyCursorSmoothing)
    private var cursorSmoothing = HeadFlowSettings.defaultCursorSmoothing
    
    @AppStorage(HeadFlowSettings.keyCursorSingleClickYawDeg)
    private var singleClickYaw = HeadFlowSettings.defaultCursorSingleClickYawDeg
    
    @AppStorage(HeadFlowSettings.keyCursorDoubleClickYawDeg)
    private var doubleClickYaw = HeadFlowSettings.defaultCursorDoubleClickYawDeg
    
    @AppStorage(HeadFlowSettings.keyCursorClickCooldown)
    private var clickCooldown = HeadFlowSettings.defaultCursorClickCooldown
    
    @AppStorage(HeadFlowSettings.keyCursorClickModifiersRaw)
    private var clickRaw: Int = HeadFlowSettings.defaultCursorClickModifiersRaw
    
    @AppStorage(HeadFlowSettings.keyCursorDragExtraModifiersRaw)
    private var dragRaw: Int = HeadFlowSettings.defaultCursorDragExtraModifiersRaw
    
    // Shortcut Enablement
    @AppStorage(HeadFlowSettings.keyGlobalToggleShortcutEnabled)
    private var globalToggleShortcutEnabled: Bool = HeadFlowSettings.defaultGlobalToggleShortcutEnabled
    
    @AppStorage(HeadFlowSettings.keyGlobalCreateProfileShortcutEnabled)
    private var globalCreateProfileShortcutEnabled: Bool = HeadFlowSettings.defaultGlobalCreateProfileShortcutEnabled
    
    @AppStorage(HeadFlowSettings.keyGlobalPreferencesShortcutEnabled)
    private var globalPreferencesShortcutEnabled: Bool = HeadFlowSettings.defaultGlobalPreferencesShortcutEnabled
    
    @AppStorage(HeadFlowSettings.keyGlobalCalibrateShortcutEnabled)
    private var globalCalibrateShortcutEnabled: Bool = HeadFlowSettings.defaultGlobalCalibrateShortcutEnabled
    
    @AppStorage(HeadFlowSettings.keyGlobalCycleModesShortcutEnabled)
    private var globalCycleModesShortcutEnabled: Bool = HeadFlowSettings.defaultGlobalCycleModesShortcutEnabled
    
    @AppStorage(HeadFlowSettings.keyGlobalDictationHUDShortcutEnabled)
    private var globalDictationHUDShortcutEnabled: Bool = HeadFlowSettings.defaultGlobalDictationHUDShortcutEnabled
    
    @AppStorage(HeadFlowSettings.keyGlobalDictationMicShortcutEnabled)
    private var globalDictationMicShortcutEnabled: Bool = HeadFlowSettings.defaultGlobalDictationMicShortcutEnabled
    
    // MARK: - Local State
    
    @State private var selectedTab: PreferencesTab = .setup
    @State private var gestureSettings: GestureSettings = HeadFlowSettings.gestureSettings
    @State private var dictationCommands: [DictationCommand] = HeadFlowSettings.dictationCustomCommands
    
    // Shortcut bindings
    @State private var toggleShortcut = HeadFlowSettings.shortcutToggle
    @State private var createProfileShortcut = HeadFlowSettings.shortcutCreateProfile
    @State private var prefsShortcut = HeadFlowSettings.shortcutPreferences
    @State private var calibrateShortcut = HeadFlowSettings.shortcutCalibrate
    @State private var cycleModesShortcut = HeadFlowSettings.shortcutCycleModes
    @State private var dictationHUDShortcut = HeadFlowSettings.shortcutDictationHUD
    @State private var dictationMicShortcut = HeadFlowSettings.shortcutDictationMic
    
    @State private var showControlsTutorial = false
    @State private var showGesturesTutorial = false
    @State private var showVoiceTutorial = false
    @State private var showAppsTutorial = false
    @State private var showShortcutsTutorial = false
    
    // UI State
    @State private var showAdvancedScrolling = false
    @State private var showAdvancedCursor = false
    @State private var showAdvancedGestures = false
    
    // Computed properties
    private var scrollMode: ScrollMode {
        get { ScrollMode(rawValue: scrollModeRaw) ?? .continuous }
        set { scrollModeRaw = newValue.rawValue }
    }
    
    private var isFullySetup: Bool {
        status.headphones == .connected &&
        status.motionAuth == .authorized &&
        status.accessibility == .enabled
    }
    
    // MARK: - Initialization
    
    init(status: HeadFlowStatus = .shared) {
        self._status = ObservedObject(wrappedValue: status)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            TabView(selection: $selectedTab) {
                setupTab
                    .tabItem { Label(PreferencesTab.setup.rawValue, systemImage: PreferencesTab.setup.icon) }
                    .tag(PreferencesTab.setup)
                
                controlsTab
                    .tabItem { Label(PreferencesTab.controls.rawValue, systemImage: PreferencesTab.controls.icon) }
                    .tag(PreferencesTab.controls)
                
                gesturesTab
                    .tabItem { Label(PreferencesTab.gestures.rawValue, systemImage: PreferencesTab.gestures.icon) }
                    .tag(PreferencesTab.gestures)
                
                voiceTab
                    .tabItem { Label(PreferencesTab.voice.rawValue, systemImage: PreferencesTab.voice.icon) }
                    .tag(PreferencesTab.voice)
                
                appsTab
                    .tabItem { Label(PreferencesTab.apps.rawValue, systemImage: PreferencesTab.apps.icon) }
                    .tag(PreferencesTab.apps)
                
                shortcutsTab
                    .tabItem { Label(PreferencesTab.shortcuts.rawValue, systemImage: PreferencesTab.shortcuts.icon) }
                    .tag(PreferencesTab.shortcuts)
                
                LicenseSectionView()
                    .tabItem { Label(PreferencesTab.license.rawValue, systemImage: PreferencesTab.license.icon) }
                    .tag(PreferencesTab.license)
            }
            .environmentObject(purchaseManager)
            .padding(.top, -8)
        }
        .frame(
            minWidth: 700,
            idealWidth: 800,
            maxWidth: .infinity,
            minHeight: 550,
            idealHeight: 650,
            maxHeight: .infinity
        )
        .onChange(of: toggleShortcut) { _, newValue in HeadFlowSettings.shortcutToggle = newValue }
        .onChange(of: createProfileShortcut) { _, newValue in HeadFlowSettings.shortcutCreateProfile = newValue }
        .onChange(of: prefsShortcut) { _, newValue in HeadFlowSettings.shortcutPreferences = newValue }
        .onChange(of: calibrateShortcut) { _, newValue in HeadFlowSettings.shortcutCalibrate = newValue }
        .onChange(of: cycleModesShortcut) { _, newValue in HeadFlowSettings.shortcutCycleModes = newValue }
        .onChange(of: dictationHUDShortcut) { _, newValue in HeadFlowSettings.shortcutDictationHUD = newValue }
        .onChange(of: dictationMicShortcut) { _, newValue in HeadFlowSettings.shortcutDictationMic = newValue }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // App Icon & Title
                HStack(spacing: 12) {
                    Image(systemName: "cursorarrow.motionlines")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PodsControlMac")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        
                        Text("Control your Mac with head movements")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Connection Status Badge
                connectionStatusBadge
            }
            .padding(.horizontal, Design.spacing)
            .padding(.top, Design.spacing)
            .padding(.bottom, 14)
            
            Divider()
        }
        .background(.background)
        .zIndex(1)
    }
    
    private var connectionStatusBadge: some View {
        HStack(spacing: 10) {
            // Device icon
            Image(systemName: status.trackingDeviceSymbolName)
                .font(.system(size: 16))
                .foregroundStyle(status.headphones == .connected ? .primary : .secondary)
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(status.headphones == .connected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(status.headphones == .connected ? "Connected" : "Not Connected")
                        .font(.system(size: 12, weight: .semibold))
                }
                
                if status.headphones == .connected, !status.audioDeviceName.isEmpty {
                    Text(status.audioDeviceName)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(status.headphones == .connected ?
                      Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(status.headphones == .connected ?
                                Color.green.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(status.headphones == .connected ?
                           "Connected to \(status.audioDeviceName)" : "Headphones not connected")
    }
    
    // MARK: - Setup Tab
    
    private var setupTab: some View {
        ScrollView {
            VStack(spacing: Design.spacing) {
                // Trial Banner
                TrialStatusBanner {
                    selectedTab = .license
                }
                
                // Quick Start Guide (for new users)
                if !isFullySetup {
                    quickStartGuide
                }
                
                // System Status
                systemStatusCard
                
                // Quick Actions
                quickActionsCard
                
                Spacer(minLength: Design.spacing)
            }
            .padding(Design.spacing)
        }
    }
    
    private var quickStartGuide: some View {
        SettingsCard(
            title: "Getting Started",
            icon: "sparkles",
            iconColor: .purple,
            description: "Complete these steps to start using PodsControlMac"
        ) {
            VStack(spacing: 14) {
                setupStepRow(
                    step: 1,
                    title: "Connect AirPods or Beats",
                    description: "Put on your headphones and ensure they're connected to your Mac",
                    isComplete: status.headphones == .connected,
                    action: nil
                )
                
                setupStepRow(
                    step: 2,
                    title: "Grant Motion Permission",
                    description: "Allow access to head tracking sensors",
                    isComplete: status.motionAuth == .authorized,
                    action: { status.refreshAll() }
                )
                
                setupStepRow(
                    step: 3,
                    title: "Enable Accessibility",
                    description: "Required to control scrolling and clicks",
                    isComplete: status.accessibility == .enabled,
                    action: { ScrollEngine.openAccessibilitySettings() }
                )
            }
        }
    }
    
    private func setupStepRow(
        step: Int,
        title: String,
        description: String,
        isComplete: Bool,
        action: (() -> Void)?
    ) -> some View {
        HStack(spacing: 14) {
            // Step number or checkmark
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green : Color.secondary.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(step)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isComplete ? .secondary : .primary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if !isComplete, let action = action {
                Button(action: action) {
                    Text("Fix")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isComplete ? Color.green.opacity(0.05) : Color.secondary.opacity(0.04))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(isComplete ? "complete" : "incomplete"). \(description)")
    }
    
    private var systemStatusCard: some View {
        SettingsCard(
            title: "System Status",
            icon: "checkmark.shield",
            iconColor: .green,
            description: "Current permission and connection status"
        ) {
            VStack(spacing: 10) {
                statusRow(
                    icon: status.trackingDeviceSymbolName,
                    title: "Headphones",
                    value: status.headphones == .connected ?
                           (status.audioDeviceName.isEmpty ? "Connected" : status.audioDeviceName) :
                           "Not connected",
                    isOK: status.headphones == .connected
                )
                
                statusRow(
                    icon: "figure.walk.motion",
                    title: "Motion Permission",
                    value: status.motionAuthDescription,
                    isOK: status.motionAuth == .authorized
                )
                
                statusRow(
                    icon: "accessibility",
                    title: "Accessibility",
                    value: status.accessibilityDescription,
                    isOK: status.accessibility == .enabled
                )
            }
        }
    }
    
    private func statusRow(icon: String, title: String, value: String, isOK: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: Design.iconSize))
                .foregroundStyle(isOK ? .green : .secondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                Text(value)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: isOK ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(isOK ? .green : .orange)
                .accessibilityLabel(isOK ? "OK" : "Needs attention")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.04))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(isOK ? "working" : "needs attention")")
    }
    
    private var quickActionsCard: some View {
        SettingsCard(
            title: "Quick Actions",
            icon: "bolt.fill",
            iconColor: .yellow,
            description: "Common tasks and system controls"
        ) {
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "Refresh",
                    action: { status.refreshAll() }
                )
                
                QuickActionButton(
                    icon: "gear",
                    title: "System Settings",
                    action: { ScrollEngine.openAccessibilitySettings() }
                )
                
                QuickActionButton(
                    icon: "scope",
                    title: "Calibrate",
                    action: {
                        // Trigger calibration via notification
                        NotificationCenter.default.post(name: .calibrateHeadPosition, object: nil)
                    }
                )
                
                Spacer()
            }
        }
    }
}

// MARK: - Reusable Components

/// A styled settings card with header and content
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var description: String? = nil
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.sectionSpacing) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: Design.headerIconSize, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
                
                if let description = description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 34)
                }
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // Content
            content()
        }
        .padding(Design.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(Design.shadowOpacity), radius: Design.shadowRadius, y: 2)
        )
    }
}

/// A quick action button for the setup tab
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.accentColor)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

/// A help popover button with info
struct HelpButton: View {
    let title: String
    let message: String
    
    @State private var isPresented = false
    
    var body: some View {
        Button(action: { isPresented.toggle() }) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: 280)
        }
        .accessibilityLabel("Help: \(title)")
        .accessibilityHint("Shows additional information")
    }
}

/// A styled toggle row with icon and optional help
struct ToggleRow: View {
    let icon: String
    let title: String
    var helpTitle: String? = nil
    var helpMessage: String? = nil
    @Binding var isOn: Bool
    var disabled: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isOn ? Color.accentColor : .secondary)
                .frame(width: 22)
                .accessibilityHidden(true)
            
            Toggle(isOn: $isOn) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(.switch)
            .disabled(disabled)
            
            if let helpTitle = helpTitle, let helpMessage = helpMessage {
                HelpButton(title: helpTitle, message: helpMessage)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}

/// A styled slider row with value display and optional help
struct SliderRow: View {
    let icon: String
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    let format: String
    var helpTitle: String? = nil
    var helpMessage: String? = nil
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                if let helpTitle = helpTitle, let helpMessage = helpMessage {
                    HelpButton(title: helpTitle, message: helpMessage)
                }
                
                Spacer()
                
                Text(String(format: format, value))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            
            if let step = step {
                Slider(value: $value, in: range, step: step)
                    .tint(.accentColor)
            } else {
                Slider(value: $value, in: range)
                    .tint(.accentColor)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 30)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(String(format: format, value))
    }
}

/// Collapsible section for advanced options
struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.secondary.opacity(0.05))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(isExpanded ? "expanded" : "collapsed")")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
            
            if isExpanded {
                VStack(alignment: .leading, spacing: Design.itemSpacing) {
                    content()
                }
                .padding(.top, 14)
                .padding(.leading, 12)
            }
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let calibrateHeadPosition = Notification.Name("calibrateHeadPosition")
}

// MARK: - Controls Tab

extension PreferencesView {
    var controlsTab: some View {
        ScrollView {
            VStack(spacing: Design.spacing) {
                // ✨ Tutorial header
                tutorialHeader(
                    title: "Controls",
                    chapterID: "basic-scrolling",
                    showTutorial: $showControlsTutorial
                )
                
                // Main Enable Toggle
                mainControlToggle
                
                // Scroll Settings
                scrollSettingsCard
                
                // Cursor Control
                cursorControlCard
                
                // Safety & Pausing
                safetySettingsCard
                
                // Advanced Tuning (Collapsible)
                advancedTuningCard
                
                Spacer(minLength: Design.spacing)
            }
            .padding(Design.spacing)
        }
        // ✨ Tutorial sheet
        .sheet(isPresented: $showControlsTutorial) {
            if let chapter = TutorialManager.getChapter(for: "basic-scrolling") {
                MuxTutorialPlayer(
                    chapter: chapter,
                    showChapterList: true,
                    onDismiss: {
                        showControlsTutorial = false
                    }
                )
            }
        }
    }
    
    private var mainControlToggle: some View {
        HStack(spacing: 16) {
            Image(systemName: isHeadScrollingEnabled ? "play.circle.fill" : "pause.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(isHeadScrollingEnabled ? .green : .secondary)
                .symbolEffect(.bounce, value: isHeadScrollingEnabled)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Head Control")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(isHeadScrollingEnabled ? "Active — tilt your head to control" : "Paused — head movements ignored")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isHeadScrollingEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .disabled(!AccessGate.hasFullAccess)
        }
        .padding(Design.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                .fill(isHeadScrollingEnabled ?
                      Color.green.opacity(0.08) : Color.secondary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                        .stroke(isHeadScrollingEnabled ?
                                Color.green.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Head Control")
        .accessibilityValue(isHeadScrollingEnabled ? "Active" : "Paused")
        .accessibilityHint("Toggle to enable or disable head control")
    }
    
    private var scrollSettingsCard: some View {
        SettingsCard(
            title: "Scroll Settings",
            icon: "scroll",
            iconColor: .blue,
            description: "Control how head tilting translates to scrolling"
        ) {
            // Scroll Mode Picker
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    
                    Text("Scroll Mode")
                        .font(.system(size: 13, weight: .medium))
                    
                    HelpButton(
                        title: "Scroll Modes",
                        message: "Continuous: Smooth, velocity-based scrolling while tilted.\n\nStep: Discrete scroll jumps at intervals.\n\nHybrid: Combines both for precise control."
                    )
                }
                
                Picker("Scroll mode", selection: $scrollModeRaw) {
                    ForEach(ScrollMode.allCases) { mode in
                        Text(mode.displayName)
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                
                Text(scrollMode.shortDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 30)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            // Sensitivity
            SliderRow(
                icon: "gauge.with.needle",
                title: "Sensitivity",
                value: $scrollSensitivity,
                range: 0...100,
                format: "%.0f",
                helpTitle: "Scroll Sensitivity",
                helpMessage: "Higher values make scrolling faster and more responsive to head movements."
            )
            
            // Max Lines
            SliderRow(
                icon: "arrow.up.arrow.down",
                title: "Max Speed (lines/sec)",
                value: $baseLines,
                range: 0...500,
                step: 10,
                format: "%.0f",
                helpTitle: "Maximum Scroll Speed",
                helpMessage: "The maximum number of lines to scroll per second when fully tilted.",
                subtitle: "Maximum lines scrolled at full tilt"
            )
        }
    }
    
    private var cursorControlCard: some View {
        SettingsCard(
            title: "Cursor Control",
            icon: "cursorarrow",
            iconColor: .purple,
            description: "Control the mouse pointer with head movements"
        ) {
            // Basic cursor settings
            SliderRow(
                icon: "cursorarrow.motionlines",
                title: "Pointer Speed",
                value: $cursorSpeed,
                range: 0.5...5.0,
                step: 0.1,
                format: "%.1fx",
                helpTitle: "Pointer Speed",
                helpMessage: "How fast the cursor moves relative to your head movement."
            )
            
            SliderRow(
                icon: "circle.dotted",
                title: "Dead Zone",
                value: $cursorDeadZone,
                range: 0.0...5.0,
                step: 0.1,
                format: "%.1f°",
                helpTitle: "Cursor Dead Zone",
                helpMessage: "Small movements within this angle won't move the cursor. Helps prevent jitter.",
                subtitle: "Ignore small movements to reduce jitter"
            )
            
            SliderRow(
                icon: "waveform.path",
                title: "Smoothing",
                value: $cursorSmoothing,
                range: 0.0...1.0,
                step: 0.05,
                format: "%.0f%%",
                helpTitle: "Motion Smoothing",
                helpMessage: "Higher values create smoother but slightly delayed cursor movement."
            )
            
            Divider()
                .padding(.vertical, 6)
            
            // Advanced cursor options
            CollapsibleSection(title: "Click Gestures", icon: "cursorarrow.click", isExpanded: $showAdvancedCursor) {
                Text("Turn your head quickly left or right to click")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 4)
                
                SliderRow(
                    icon: "cursorarrow.click",
                    title: "Single Click Angle",
                    value: $singleClickYaw,
                    range: 5.0...30.0,
                    step: 1.0,
                    format: "%.0f°"
                )
                
                SliderRow(
                    icon: "cursorarrow.rays",
                    title: "Double Click Angle",
                    value: Binding(
                        get: { doubleClickYaw },
                        set: { doubleClickYaw = max($0, singleClickYaw + 1.0) }
                    ),
                    range: 8.0...40.0,
                    step: 1.0,
                    format: "%.0f°"
                )
                
                SliderRow(
                    icon: "timer",
                    title: "Click Cooldown",
                    value: $clickCooldown,
                    range: 0.1...1.5,
                    step: 0.05,
                    format: "%.2fs",
                    subtitle: "Prevents accidental double-triggers"
                )
                
                Divider()
                    .padding(.vertical, 6)
                
                // Modifier pickers
                let allowedFlags: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
                
                CursorModifierPicker(
                    title: "Click Modifier Keys",
                    flags: Binding(
                        get: { NSEvent.ModifierFlags(rawValue: UInt(clickRaw)) },
                        set: { newFlags in
                            var filtered = newFlags.intersection(allowedFlags)
                            if filtered.isEmpty { filtered = [.command] }
                            clickRaw = Int(filtered.rawValue)
                        }
                    )
                )
                
                CursorModifierPicker(
                    title: "Additional Drag Modifiers",
                    flags: Binding(
                        get: { NSEvent.ModifierFlags(rawValue: UInt(dragRaw)) },
                        set: { dragRaw = Int($0.intersection(allowedFlags).rawValue) }
                    )
                )
                
                Text("Hold these keys while performing head gestures to click or drag")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var safetySettingsCard: some View {
        SettingsCard(
            title: "Safety & Pausing",
            icon: "hand.raised",
            iconColor: .orange,
            description: "Automatically pause head control in certain situations"
        ) {
            ToggleRow(
                icon: "cursorarrow",
                title: "Pause while using mouse/trackpad",
                helpTitle: "Mouse Detection",
                helpMessage: "Automatically pauses head control when you move the mouse or trackpad.",
                isOn: $pauseWhilePointerActive
            )
            
            ToggleRow(
                icon: "keyboard",
                title: "Pause while typing",
                helpTitle: "Typing Detection",
                helpMessage: "Pauses head control during keyboard input to prevent accidental scrolling.",
                isOn: $pauseWhileTyping
            )
            
            ToggleRow(
                icon: "shift",
                title: "Hold Shift to pause",
                helpTitle: "Quick Pause",
                helpMessage: "Hold the Shift key to temporarily disable head control.",
                isOn: $shiftToPauseEnabled
            )
            
            Divider()
                .padding(.vertical, 4)
            
            ToggleRow(
                icon: "scroll",
                title: "Pause after manual scroll",
                isOn: $pauseOnManualScroll
            )
            
            if pauseOnManualScroll {
                SliderRow(
                    icon: "timer",
                    title: "Pause Duration",
                    value: $manualScrollPauseSeconds,
                    range: 0.1...5.0,
                    step: 0.1,
                    format: "%.1fs",
                    subtitle: "Resume head control after this delay"
                )
                .padding(.leading, 32)
            }
        }
    }
    
    private var advancedTuningCard: some View {
        SettingsCard(
            title: "Advanced Tuning",
            icon: "slider.horizontal.3",
            iconColor: .gray,
            description: "Fine-tune the physics of head-based scrolling"
        ) {
            SliderRow(
                icon: "circle.dotted",
                title: "Scroll Dead Zone",
                value: $deadZoneDegrees,
                range: 0...15,
                step: 0.5,
                format: "%.1f°",
                helpTitle: "Dead Zone",
                helpMessage: "Head movements smaller than this angle won't trigger scrolling. Helps filter out natural head sway.",
                subtitle: "Ignore small movements"
            )
            
            SliderRow(
                icon: "speedometer",
                title: "Max Tilt Angle",
                value: $maxTiltDegrees,
                range: 10...45,
                step: 1,
                format: "%.0f°",
                helpTitle: "Maximum Tilt",
                helpMessage: "The tilt angle at which scroll speed reaches its maximum. Smaller values = faster acceleration.",
                subtitle: "Angle for maximum scroll speed"
            )
            
            SliderRow(
                icon: "hare",
                title: "Acceleration",
                value: $accelerationFactor,
                range: 0.5...5.0,
                step: 0.1,
                format: "%.1fx",
                helpTitle: "Acceleration Factor",
                helpMessage: "Controls how quickly scroll speed ramps up. Higher = faster acceleration curve.",
                subtitle: "How quickly speed builds up"
            )
            
            SliderRow(
                icon: "tortoise",
                title: "Damping",
                value: $dampingFactor,
                range: 0.5...5.0,
                step: 0.1,
                format: "%.1fx",
                helpTitle: "Damping Factor",
                helpMessage: "Controls how quickly scrolling slows down when you return to neutral. Higher = faster stopping.",
                subtitle: "How quickly scrolling stops"
            )
            
            Divider()
                .padding(.vertical, 6)
            
            Button(action: resetAdvancedSettings) {
                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
    
    private func resetAdvancedSettings() {
        withAnimation(.spring(response: Design.springResponse, dampingFraction: Design.springDamping)) {
            scrollSensitivity = HeadFlowSettings.defaultScrollSensitivity
            baseLines = HeadFlowSettings.defaultBaseLines
            deadZoneDegrees = HeadFlowSettings.defaultDeadZoneDegrees
            maxTiltDegrees = HeadFlowSettings.defaultMaxTiltDegrees
            accelerationFactor = HeadFlowSettings.defaultAccelerationFactor
            dampingFactor = HeadFlowSettings.defaultDampingFactor
            scrollModeRaw = ScrollMode.continuous.rawValue
        }
    }
}

// MARK: - Voice Tab

extension PreferencesView {
    var voiceTab: some View {
        ScrollView {
            VStack(spacing: Design.spacing) {
                // ✨ Tutorial header
                tutorialHeader(
                    title: "Voice",
                    chapterID: "voice-dictation",
                    showTutorial: $showVoiceTutorial
                )
                
                // Intro Card
                voiceIntroCard
                
                // Dictation Settings
                dictationSettingsCard
                
                // Voice Commands
                voiceCommandsCard
                
                Spacer(minLength: Design.spacing)
            }
            .padding(Design.spacing)
        }
        // ✨ Tutorial sheet
        .sheet(isPresented: $showVoiceTutorial) {
            if let chapter = TutorialManager.getChapter(for: "voice-dictation") {
                MuxTutorialPlayer(
                    chapter: chapter,
                    showChapterList: true,
                    onDismiss: {
                        showVoiceTutorial = false
                    }
                )
            }
        }
    }
    
    private var voiceIntroCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(.linearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Voice Control")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Use your voice to dictate text and trigger custom commands")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(Design.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                .fill(.linearGradient(
                    colors: [Color.purple.opacity(0.08), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
    }
    
    private var dictationSettingsCard: some View {
        SettingsCard(
            title: "Dictation",
            icon: "mic.fill",
            iconColor: .red,
            description: "Configure how voice dictation behaves"
        ) {
            ToggleRow(
                icon: "pause.circle",
                title: "Pause head control while dictating",
                helpTitle: "Pause During Dictation",
                helpMessage: "Prevents head movements from scrolling while you're speaking to dictate text.",
                isOn: $dictationPausesHeadFlow
            )
            
            Divider()
                .padding(.vertical, 6)
            
            ToggleRow(
                icon: "timer.circle",
                title: "Auto-commit after silence",
                helpTitle: "Auto-Commit",
                helpMessage: "Automatically insert dictated text when you stop speaking for a set duration.",
                isOn: $dictationAutoCommitEnabled
            )
            
            if dictationAutoCommitEnabled {
                SliderRow(
                    icon: "timer",
                    title: "Silence Delay",
                    value: $dictationAutoCommitDelaySeconds,
                    range: 0.5...10.0,
                    step: 0.5,
                    format: "%.1fs",
                    subtitle: "Wait this long after you stop speaking to commit"
                )
                .padding(.leading, 32)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Label("How to Use Dictation", systemImage: "lightbulb")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.yellow)
                
                VStack(alignment: .leading, spacing: 6) {
                    tipItem("Use the keyboard shortcut to toggle dictation HUD")
                    tipItem("Speak clearly and at a normal pace")
                    tipItem("Say punctuation like 'comma' or 'period'")
                    tipItem("Say 'new line' or 'new paragraph' for formatting")
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.yellow.opacity(0.08))
            )
        }
    }
    
    private func tipItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.green)
                .padding(.top, 2)
            
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
    
    private var voiceCommandsCard: some View {
        SettingsCard(
            title: "Voice Commands",
            icon: "text.bubble.fill",
            iconColor: .green,
            description: "Create custom phrases that trigger text replacement"
        ) {
            if dictationCommands.isEmpty {
                emptyCommandsView
            } else {
                VStack(spacing: 10) {
                    ForEach(dictationCommands) { command in
                        voiceCommandRow(command: command)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 6)
            
            Button(action: addDictationCommand) {
                Label("Add Voice Command", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }
    
    private var emptyCommandsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            
            Text("No Voice Commands")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text("Add custom phrases like \"my email\" → \"user@example.com\"")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private func voiceCommandRow(command: DictationCommand) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("When I say:")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                
                TextField("Trigger phrase", text: bindingForCommandTrigger(command))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .frame(minWidth: 120)
            }
            
            Image(systemName: "arrow.right")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Type this:")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                
                TextField("Replacement text", text: bindingForCommandReplacement(command))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .frame(minWidth: 160)
            }
            
            Spacer()
            
            Button(role: .destructive, action: { removeDictationCommand(command) }) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
            }
            .buttonStyle(.borderless)
            .help("Remove this command")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.04))
        )
    }
    
    // Voice command bindings
    private func bindingForCommandTrigger(_ command: DictationCommand) -> Binding<String> {
        Binding<String>(
            get: {
                dictationCommands.first(where: { $0.id == command.id })?.trigger ?? ""
            },
            set: { newValue in
                if let index = dictationCommands.firstIndex(where: { $0.id == command.id }) {
                    dictationCommands[index].trigger = newValue
                    HeadFlowSettings.dictationCustomCommands = dictationCommands
                }
            }
        )
    }
    
    private func bindingForCommandReplacement(_ command: DictationCommand) -> Binding<String> {
        Binding<String>(
            get: {
                dictationCommands.first(where: { $0.id == command.id })?.replacement ?? ""
            },
            set: { newValue in
                if let index = dictationCommands.firstIndex(where: { $0.id == command.id }) {
                    dictationCommands[index].replacement = newValue
                    HeadFlowSettings.dictationCustomCommands = dictationCommands
                }
            }
        )
    }
    
    private func addDictationCommand() {
        let new = DictationCommand(trigger: "say this", replacement: "types this")
        dictationCommands.append(new)
        HeadFlowSettings.dictationCustomCommands = dictationCommands
    }
    
    private func removeDictationCommand(_ command: DictationCommand) {
        dictationCommands.removeAll { $0.id == command.id }
        HeadFlowSettings.dictationCustomCommands = dictationCommands
    }
}

// MARK: - Gestures Tab

extension PreferencesView {
    var gesturesTab: some View {
        ScrollView {
            VStack(spacing: Design.spacing) {
                // ✨ Tutorial header
                tutorialHeader(
                    title: "Gestures",
                    chapterID: "gestures",
                    showTutorial: $showGesturesTutorial
                )
                
                // Intro
                gestureIntroCard
                
                // Gesture Sensitivity
                gestureSensitivityCard
                
                // When ON gestures
                gestureActionsCard(
                    title: "When Head Control is ON",
                    icon: "play.circle.fill",
                    iconColor: .green,
                    description: "Actions triggered while head scrolling is active",
                    context: .headFlowOn
                )
                
                // When OFF gestures
                gestureActionsCard(
                    title: "When Head Control is OFF",
                    icon: "pause.circle.fill",
                    iconColor: .gray,
                    description: "Actions triggered while head scrolling is paused",
                    context: .headFlowOff
                )
                
                // Custom Shortcuts Bank
                customShortcutsCard
                
                Spacer(minLength: Design.spacing)
            }
            .padding(Design.spacing)
        }
        // ✨ Tutorial sheet
        .sheet(isPresented: $showGesturesTutorial) {
            if let chapter = TutorialManager.getChapter(for: "gestures") {
                MuxTutorialPlayer(
                    chapter: chapter,
                    showChapterList: true,
                    onDismiss: {
                        showGesturesTutorial = false
                    }
                )
            }
        }
    }
    
    private var gestureIntroCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 42))
                .foregroundStyle(.linearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Head Gestures")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Tilt your head sharply to trigger actions like scrolling, clicking, or custom shortcuts")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(Design.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                .fill(.linearGradient(
                    colors: [Color.orange.opacity(0.08), Color.red.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
    }
    
    private var gestureSensitivityCard: some View {
        SettingsCard(
            title: "Gesture Sensitivity",
            icon: "dial.medium",
            iconColor: .orange,
            description: "Control when gestures are recognized"
        ) {
            SliderRow(
                icon: "angle",
                title: "Tilt Threshold",
                value: $gestureTiltThresholdDegrees,
                range: 10...50,
                step: 1,
                format: "%.0f°",
                helpTitle: "Tilt Threshold",
                helpMessage: "How far you need to tilt your head for a gesture to be recognized. Lower values = more sensitive.",
                subtitle: "Minimum angle to trigger a gesture"
            )
            
            SliderRow(
                icon: "timer",
                title: "Cooldown",
                value: $gestureCooldownSeconds,
                range: 0.2...10.0,
                step: 0.1,
                format: "%.1fs",
                helpTitle: "Gesture Cooldown",
                helpMessage: "Minimum time between gesture triggers. Prevents accidental repeated gestures.",
                subtitle: "Wait time between gestures"
            )
        }
    }
    
    private func gestureActionsCard(
        title: String,
        icon: String,
        iconColor: Color,
        description: String,
        context: GestureContext
    ) -> some View {
        SettingsCard(
            title: title,
            icon: icon,
            iconColor: iconColor,
            description: description
        ) {
            gestureRow(
                title: "Tilt / Look Right",
                icon: "arrow.right.circle",
                context: context,
                gesture: .tiltLeft
            )
            
            gestureRow(
                title: "Tilt / Look Left",
                icon: "arrow.left.circle",
                context: context,
                gesture: .tiltRight
            )
        }
    }
    
    private func gestureRow(
        title: String,
        icon: String,
        context: GestureContext,
        gesture: GestureType
    ) -> some View {
        let selection = bindingForGesture(context: context, gesture: gesture)
        
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
            
            Picker("Action", selection: selection) {
                Text("None")
                    .tag(GestureAction.none)
                
                Section("HeadFlow Actions") {
                    ForEach(HeadFlowActionKind.allCases) { kind in
                        Text(kind.displayName)
                            .tag(GestureAction.headFlow(kind))
                    }
                }
                
                Section("macOS Actions") {
                    ForEach(StandardShortcutKind.allCases) { kind in
                        Text(kind.displayName)
                            .tag(GestureAction.standardShortcut(kind))
                    }
                }
                
                if !gestureSettings.customShortcuts.isEmpty {
                    Section("Custom Shortcuts") {
                        ForEach(gestureSettings.customShortcuts) { custom in
                            Text(custom.name)
                                .tag(GestureAction.customShortcut(custom.id))
                        }
                    }
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.04))
        )
    }
    
    private var customShortcutsCard: some View {
        SettingsCard(
            title: "Custom Shortcuts",
            icon: "star.circle.fill",
            iconColor: .yellow,
            description: "Define reusable keyboard shortcuts for gestures"
        ) {
            if gestureSettings.customShortcuts.isEmpty {
                emptyShortcutsView
            } else {
                VStack(spacing: 10) {
                    ForEach(gestureSettings.customShortcuts) { custom in
                        customShortcutRow(custom: custom)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 6)
            
            Button(action: addCustomShortcut) {
                Label("Add Custom Shortcut", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }
    
    private var emptyShortcutsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "keyboard")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            
            Text("No Custom Shortcuts")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text("Create shortcuts like ⌘C for Copy, then assign them to head gestures above")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private func customShortcutRow(custom: CustomShortcut) -> some View {
        HStack(spacing: 12) {
            TextField("Shortcut name", text: bindingForCustomShortcutName(custom))
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))
                .frame(minWidth: 140)
            
            ShortcutRecorderField(shortcut: bindingForCustomShortcutValue(custom))
                .frame(width: 160)
            
            Button(role: .destructive, action: { removeCustomShortcut(custom) }) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
            }
            .buttonStyle(.borderless)
            .help("Remove this shortcut")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.04))
        )
    }
    
    // Gesture bindings
    private func bindingForGesture(context: GestureContext, gesture: GestureType) -> Binding<GestureAction> {
        Binding<GestureAction>(
            get: {
                if let index = gestureSettings.mappings.firstIndex(where: {
                    $0.context == context && $0.gesture == gesture
                }) {
                    return gestureSettings.mappings[index].action
                }
                return .none
            },
            set: { newValue in
                var settings = gestureSettings
                if let index = settings.mappings.firstIndex(where: {
                    $0.context == context && $0.gesture == gesture
                }) {
                    settings.mappings[index].action = newValue
                } else {
                    settings.mappings.append(GestureMapping(context: context, gesture: gesture, action: newValue))
                }
                gestureSettings = settings
                HeadFlowSettings.gestureSettings = settings
            }
        )
    }
    
    private func bindingForCustomShortcutName(_ custom: CustomShortcut) -> Binding<String> {
        Binding<String>(
            get: { gestureSettings.customShortcuts.first(where: { $0.id == custom.id })?.name ?? custom.name },
            set: { newValue in
                var settings = gestureSettings
                if let index = settings.customShortcuts.firstIndex(where: { $0.id == custom.id }) {
                    settings.customShortcuts[index].name = newValue
                    gestureSettings = settings
                    HeadFlowSettings.gestureSettings = settings
                }
            }
        )
    }
    
    private func bindingForCustomShortcutValue(_ custom: CustomShortcut) -> Binding<KeyboardShortcut> {
        Binding<KeyboardShortcut>(
            get: { gestureSettings.customShortcuts.first(where: { $0.id == custom.id })?.shortcut ?? custom.shortcut },
            set: { newShortcut in
                var settings = gestureSettings
                if let index = settings.customShortcuts.firstIndex(where: { $0.id == custom.id }) {
                    settings.customShortcuts[index].shortcut = newShortcut
                    gestureSettings = settings
                    HeadFlowSettings.gestureSettings = settings
                }
            }
        )
    }
    
    private func addCustomShortcut() {
        var settings = gestureSettings
        settings.customShortcuts.append(CustomShortcut(id: UUID(), name: "My Shortcut", shortcut: .none))
        gestureSettings = settings
        HeadFlowSettings.gestureSettings = settings
    }
    
    private func removeCustomShortcut(_ custom: CustomShortcut) {
        var settings = gestureSettings
        settings.customShortcuts.removeAll { $0.id == custom.id }
        for index in settings.mappings.indices {
            if case .customShortcut(let id) = settings.mappings[index].action, id == custom.id {
                settings.mappings[index].action = .none
            }
        }
        gestureSettings = settings
        HeadFlowSettings.gestureSettings = settings
    }
}

// MARK: - Apps Tab

extension PreferencesView {
    var appsTab: some View {
        ScrollView {
            VStack(spacing: Design.spacing) {
                // ✨ Tutorial header
                tutorialHeader(
                    title: "Apps",
                    chapterID: "per-app-profiles",
                    showTutorial: $showAppsTutorial
                )
                
                // Current Profile Status
                currentProfileCard
                
                // How to Create Profiles
                createProfileGuide
                
                // Profile List
                if profileManager.profiles.isEmpty {
                    emptyProfilesView
                } else {
                    ForEach(profileManager.profiles) { profile in
                        profileCard(profile: profile)
                    }
                }
                
                Spacer(minLength: Design.spacing)
            }
            .padding(Design.spacing)
        }
        // ✨ Tutorial sheet
        .sheet(isPresented: $showAppsTutorial) {
            if let chapter = TutorialManager.getChapter(for: "per-app-profiles") {
                MuxTutorialPlayer(
                    chapter: chapter,
                    showChapterList: true,
                    onDismiss: {
                        showAppsTutorial = false
                    }
                )
            }
        }
    }
    
    private var currentProfileCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "app.badge.checkmark.fill")
                .font(.system(size: 36))
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Profile")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(status.currentProfileSummary)
                    .font(.system(size: 15, weight: .semibold))
            }
            
            Spacer()
        }
        .padding(Design.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                .fill(Color.purple.opacity(0.08))
        )
    }
    
    private var createProfileGuide: some View {
        SettingsCard(
            title: "Per-App Profiles",
            icon: "square.grid.2x2",
            iconColor: .purple,
            description: "Customize settings for individual applications"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                guideStep(
                    number: 1,
                    text: "Open any app you want to customize"
                )
                
                guideStep(
                    number: 2,
                    text: "Click the PodsControlMac menu bar icon"
                )
                
                guideStep(
                    number: 3,
                    text: "Select 'Create profile for current app'"
                )
            }
            
            Divider()
                .padding(.vertical, 6)
            
            HStack {
                Image(systemName: "keyboard")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                Text("Or use the keyboard shortcut:")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                Text(createProfileShortcut.displayString.isEmpty ? "Not set" : createProfileShortcut.displayString)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
        }
    }
    
    private func guideStep(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 26, height: 26)
                
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }
            
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
    
    private var emptyProfilesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            
            Text("No App Profiles Yet")
                .font(.system(size: 17, weight: .semibold))
            
            Text("Create your first profile by following the guide above.\nEach app can have its own scroll sensitivity and settings.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(Design.shadowOpacity), radius: Design.shadowRadius, y: 2)
        )
    }
    
    private func profileCard(profile: AppProfile) -> some View {
        SettingsCard(
            title: profile.appName,
            icon: "app.fill",
            iconColor: .purple,
            description: profile.bundleIdentifier
        ) {
            ToggleRow(
                icon: "power",
                title: "Enable head control in this app",
                isOn: binding(for: profile, keyPath: \.isEnabled)
            )
            
            Divider()
                .padding(.vertical, 6)
            
            SliderRow(
                icon: "gauge.with.needle",
                title: "Scroll Sensitivity",
                value: binding(for: profile, keyPath: \.scrollSensitivity),
                range: 0...100,
                format: "%.0f"
            )
            
            SliderRow(
                icon: "arrow.up.arrow.down",
                title: "Max Lines at Full Tilt",
                value: binding(for: profile, keyPath: \.baseLines),
                range: 0...500,
                step: 10,
                format: "%.0f"
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    
                    Text("Scroll Mode")
                        .font(.system(size: 13, weight: .medium))
                }
                
                Picker("Scroll mode", selection: binding(for: profile, keyPath: \.scrollModeRaw)) {
                    ForEach(ScrollMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
            Divider()
                .padding(.vertical, 6)
            
            HStack {
                Spacer()
                
                Button(role: .destructive, action: { ProfileManager.shared.removeProfile(profile) }) {
                    Label("Remove Profile", systemImage: "trash")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    // Profile binding helper
    private func binding<Value>(for profile: AppProfile, keyPath: WritableKeyPath<AppProfile, Value>) -> Binding<Value> {
        Binding<Value>(
            get: {
                guard let index = profileManager.profiles.firstIndex(where: { $0.id == profile.id }) else {
                    return profile[keyPath: keyPath]
                }
                return profileManager.profiles[index][keyPath: keyPath]
            },
            set: { newValue in
                guard let index = profileManager.profiles.firstIndex(where: { $0.id == profile.id }) else { return }
                profileManager.profiles[index][keyPath: keyPath] = newValue
            }
        )
    }
}

// MARK: - Shortcuts Tab

extension PreferencesView {
    var shortcutsTab: some View {
        ScrollView {
            VStack(spacing: Design.spacing) {
                // ✨ Tutorial header
                tutorialHeader(
                    title: "Shortcuts",
                    chapterID: "keyboard-shortcuts",
                    showTutorial: $showShortcutsTutorial
                )
                
                // Info banner
                shortcutsInfoBanner
                
                // Main shortcuts
                mainShortcutsCard
                
                // Dictation shortcuts
                dictationShortcutsCard
                
                // Tips
                shortcutsTipsCard
                
                Spacer(minLength: Design.spacing)
            }
            .padding(Design.spacing)
        }
        // ✨ Tutorial sheet
        .sheet(isPresented: $showShortcutsTutorial) {
            if let chapter = TutorialManager.getChapter(for: "keyboard-shortcuts") {
                MuxTutorialPlayer(
                    chapter: chapter,
                    showChapterList: true,
                    onDismiss: {
                        showShortcutsTutorial = false
                    }
                )
            }
        }
    }
    
    private var shortcutsInfoBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.accentColor)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Global Keyboard Shortcuts")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("These shortcuts work anywhere, even when other apps are focused")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(Design.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                .fill(Color.accentColor.opacity(0.08))
        )
    }
    
    private var mainShortcutsCard: some View {
        SettingsCard(
            title: "Application Controls",
            icon: "command",
            iconColor: .accentColor,
            description: "Core application shortcuts"
        ) {
            shortcutRow(
                icon: "play.circle",
                title: "Start/Stop Head Control",
                enabled: $globalToggleShortcutEnabled,
                shortcut: $toggleShortcut
            )
            
            shortcutRow(
                icon: "plus.app",
                title: "Create Profile for Current App",
                enabled: $globalCreateProfileShortcutEnabled,
                shortcut: $createProfileShortcut
            )
            
            shortcutRow(
                icon: "gearshape",
                title: "Open Preferences",
                enabled: $globalPreferencesShortcutEnabled,
                shortcut: $prefsShortcut
            )
            
            shortcutRow(
                icon: "scope",
                title: "Calibrate Head Position",
                enabled: $globalCalibrateShortcutEnabled,
                shortcut: $calibrateShortcut
            )
            
            shortcutRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Cycle Mode (Scroll ↔ Cursor)",
                enabled: $globalCycleModesShortcutEnabled,
                shortcut: $cycleModesShortcut
            )
        }
    }
    
    private var dictationShortcutsCard: some View {
        SettingsCard(
            title: "Dictation",
            icon: "mic.fill",
            iconColor: .red,
            description: "Voice input shortcuts"
        ) {
            shortcutRow(
                icon: "bubble.left.and.bubble.right",
                title: "Toggle Dictation HUD",
                enabled: $globalDictationHUDShortcutEnabled,
                shortcut: $dictationHUDShortcut
            )
            
            shortcutRow(
                icon: "mic",
                title: "Start/Stop Dictation",
                enabled: $globalDictationMicShortcutEnabled,
                shortcut: $dictationMicShortcut
            )
        }
    }
    
    private func shortcutRow(
        icon: String,
        title: String,
        enabled: Binding<Bool>,
        shortcut: Binding<KeyboardShortcut>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(enabled.wrappedValue ? Color.accentColor : .secondary)
                .frame(width: 24)
            
            Toggle(isOn: enabled) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(.switch)
            
            Spacer()
            
            ShortcutRecorderButton(shortcut: shortcut)
                .disabled(!enabled.wrappedValue)
                .opacity(enabled.wrappedValue ? 1.0 : 0.5)
        }
        .padding(.vertical, 6)
    }
    
    private var shortcutsTipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
                
                Text("Tips for Setting Shortcuts")
                    .font(.system(size: 14, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "hand.tap", text: "Click the shortcut button to record a new key combination")
                tipRow(icon: "escape", text: "Press Escape while recording to clear the shortcut")
                tipRow(icon: "exclamationmark.triangle", text: "Avoid shortcuts used by other apps to prevent conflicts")
                tipRow(icon: "power", text: "Disable shortcuts you don't use to free up key combinations")
            }
        }
        .padding(Design.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                .fill(Color.yellow.opacity(0.08))
        )
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - ✨ Tutorial Header Helper (NEW)

extension PreferencesView {
    /// Reusable tutorial header component for all tabs
    private func tutorialHeader(
        title: String,
        chapterID: String,
        showTutorial: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "film")
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
                
                Text("\(title) Tutorial")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: {
                showTutorial.wrappedValue = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                    Text("Watch")
                }
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.1))
                )
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Watch \(title.lowercased()) tutorial")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

/// Field style shortcut recorder
struct ShortcutRecorderField: View {
    @Binding var shortcut: KeyboardShortcut
    @State private var isRecording = false
    @State private var localMonitor: Any?
    
    var body: some View {
        Button(action: toggleRecording) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isRecording ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isRecording ? Color.accentColor.opacity(0.08) : Color.clear)
                        )
                )
        }
        .buttonStyle(.plain)
        .onDisappear { stopRecording() }
    }
    
    private var label: String {
        if isRecording { return "Press keys..." }
        if shortcut.isEmpty { return "Not set" }
        return shortcut.displayString
    }
    
    private func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }
    
    private func startRecording() {
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleEvent(event)
            return nil
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        defer { stopRecording() }
        
        if event.keyCode == 53 {
            shortcut = .none
            return
        }
        
        let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
        guard let first = chars.first else { return }
        
        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard !mods.isEmpty else {
            shortcut = .none
            return
        }
        
        shortcut = KeyboardShortcut(key: String(first), modifiers: mods)
    }
}

/// Cursor modifier picker for click/drag combos
struct CursorModifierPicker: View {
    let title: String
    @Binding var flags: NSEvent.ModifierFlags
    
    private let allKeys = CursorModifierKey.allCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                ForEach(allKeys) { key in
                    Toggle(key.displayName, isOn: Binding(
                        get: { flags.contains(key.eventFlag) },
                        set: { isOn in
                            var newFlags = flags
                            if isOn {
                                newFlags.insert(key.eventFlag)
                            } else {
                                newFlags.remove(key.eventFlag)
                            }
                            if !newFlags.isEmpty {
                                flags = newFlags
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                }
            }
        }
    }
}

// MARK: - Label Style Extension

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
        }
    }
}

// MARK: - Preview

#Preview {
    PreferencesView()
        .frame(width: 800, height: 650)
}
