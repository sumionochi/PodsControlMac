//PreferencesView
import SwiftUI
import AppKit



/// Professional redesigned preferences UI for HeadFlow with standardized spacing and layout
struct PreferencesView: View {
    // Status from MotionEngine / AppDelegate
    @ObservedObject private var status: HeadFlowStatus
    
    // Live telemetry for the "Live response" panel
    @ObservedObject private var live = MotionLiveState.shared
    @ObservedObject private var headphones = HeadphoneDeviceState.shared
    
    // Per-app profiles
    @ObservedObject private var profileManager = ProfileManager.shared
    
    // Normal settings (global)
    @AppStorage(HeadFlowSettings.keyGestureTiltThresholdDegrees)
    private var gestureTiltThresholdDegrees: Double = HeadFlowSettings.defaultGestureTiltThresholdDegrees
    
    @AppStorage(HeadFlowSettings.keyGestureCooldownSeconds)
    private var gestureCooldownSeconds: Double = HeadFlowSettings.defaultGestureCooldownSeconds
    
    @AppStorage(HeadFlowSettings.keyIsHeadScrollingEnabled)
    private var isHeadScrollingEnabled: Bool = HeadFlowSettings.defaultIsHeadScrollingEnabled
    
    @AppStorage(HeadFlowSettings.keyScrollSensitivity)
    private var scrollSensitivity: Double = HeadFlowSettings.defaultScrollSensitivity
    
    @AppStorage(HeadFlowSettings.keyDictationPausesHeadFlow)
    private var dictationPausesHeadFlow: Bool = HeadFlowSettings.defaultDictationPausesHeadFlow
    
    @AppStorage(HeadFlowSettings.keyDictationAutoCommitEnabled)
    private var dictationAutoCommitEnabled: Bool = HeadFlowSettings.defaultDictationAutoCommitEnabled
    
    @AppStorage(HeadFlowSettings.keyBaseLines)
    private var baseLines: Double = HeadFlowSettings.defaultBaseLines
    
    // Advanced tuning (global)
    @AppStorage(HeadFlowSettings.keyDeadZoneDegrees)
    private var deadZoneDegrees: Double = HeadFlowSettings.defaultDeadZoneDegrees
    
    @AppStorage(HeadFlowSettings.keyMaxTiltDegrees)
    private var maxTiltDegrees: Double = HeadFlowSettings.defaultMaxTiltDegrees
    
    @AppStorage(HeadFlowSettings.keyDictationAutoCommitDelaySeconds)
    private var dictationAutoCommitDelaySeconds: Double = HeadFlowSettings.defaultDictationAutoCommitDelaySeconds
    
    @AppStorage(HeadFlowSettings.keyAccelerationFactor)
    private var accelerationFactor: Double = HeadFlowSettings.defaultAccelerationFactor
    
    @AppStorage(HeadFlowSettings.keyDampingFactor)
    private var dampingFactor: Double = HeadFlowSettings.defaultDampingFactor
    
    @AppStorage(HeadFlowSettings.keyPauseWhilePointerActive)
    private var pauseWhilePointerActive: Bool = HeadFlowSettings.defaultPauseWhilePointerActive
    
    @AppStorage(HeadFlowSettings.keyPauseWhileTyping)
    private var pauseWhileTyping: Bool = HeadFlowSettings.defaultPauseWhileTyping
    
    @AppStorage(HeadFlowSettings.keyShiftToPauseEnabled)
    private var shiftToPauseEnabled: Bool = HeadFlowSettings.defaultShiftToPauseEnabled
    
    // Scroll mode (stored as raw Int)
    @AppStorage(HeadFlowSettings.keyScrollMode)
    private var scrollModeRaw: Int = HeadFlowSettings.defaultScrollModeRaw
    
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
    
    @AppStorage(HeadFlowSettings.keyPauseOnManualScroll)
    private var pauseOnManualScroll: Bool = HeadFlowSettings.defaultPauseOnManualScroll
    
    @AppStorage(HeadFlowSettings.keyManualScrollPauseSeconds)
    private var manualScrollPauseSeconds: Double = HeadFlowSettings.defaultManualScrollPauseSeconds
    
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
    
    private var scrollMode: ScrollMode {
        get { ScrollMode(rawValue: scrollModeRaw) ?? .continuous }
        set { scrollModeRaw = newValue.rawValue }
    }
    
    // Local UI-only state
    @State private var selectedTab: Tab = .overview
    @State private var lastStatusCheck: Date? = nil
    @State private var gestureSettings: GestureSettings = HeadFlowSettings.gestureSettings
    @State private var toggleShortcut = HeadFlowSettings.shortcutToggle
    @State private var createProfileShortcut = HeadFlowSettings.shortcutCreateProfile
    @State private var prefsShortcut = HeadFlowSettings.shortcutPreferences
    @State private var calibrateShortcut = HeadFlowSettings.shortcutCalibrate
    @State private var cycleModesShortcut = HeadFlowSettings.shortcutCycleModes // <--- New
    // Design system constants
    private let spacing: CGFloat = 20
    private let cardRadius: CGFloat = 12
    private let sectionSpacing: CGFloat = 16
    private let iconSize: CGFloat = 16
    private let statusWidth: CGFloat = 120
    
    
    
    // Tab enumeration
    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case scrolling = "Scrolling"
        case gestures = "Gestures"
        case apps = "Apps"
        case advanced = "Advanced"
        case shortcuts = "Shortcuts"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .overview: return "gauge.with.dots.needle.67percent"
            case .scrolling: return "scroll"
            case .gestures: return "hand.point.up.left"
            case .apps: return "square.grid.2x2"
            case .advanced: return "slider.horizontal.3"
            case .shortcuts: return "keyboard"
            }
        }
    }
    
    init(status: HeadFlowStatus = .shared) {
        self._status = ObservedObject(wrappedValue: status)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app title
            headerView
            
            // Main tab view
            TabView(selection: $selectedTab) {
                overviewTab
                    .tabItem {
                        Label(Tab.overview.rawValue, systemImage: Tab.overview.icon)
                    }
                    .tag(Tab.overview)
                
                scrollingTab
                    .tabItem {
                        Label(Tab.scrolling.rawValue, systemImage: Tab.scrolling.icon)
                    }
                    .tag(Tab.scrolling)
                
                gesturesTab
                    .tabItem {
                        Label(Tab.gestures.rawValue, systemImage: Tab.gestures.icon)
                    }
                    .tag(Tab.gestures)
                
                appsTab
                    .tabItem {
                        Label(Tab.apps.rawValue, systemImage: Tab.apps.icon)
                    }
                    .tag(Tab.apps)
                
                advancedTab
                    .tabItem {
                        Label(Tab.advanced.rawValue, systemImage: Tab.advanced.icon)
                    }
                    .tag(Tab.advanced)
                
                shortcutsTab
                    .tabItem {
                        Label(Tab.shortcuts.rawValue, systemImage: Tab.shortcuts.icon)
                    }
                    .tag(Tab.shortcuts)
            }
            .padding(.top, -8)
        }
        .frame(
            minWidth: 650,
            idealWidth: 750,
            maxWidth: .infinity,
            minHeight: 500,
            idealHeight: 600,
            maxHeight: .infinity
        )
        .onAppear {
            status.refreshAll()
            lastStatusCheck = Date()
            
            let validModes = Set(ScrollMode.allCases.map { $0.rawValue })
            if !validModes.contains(scrollModeRaw) {
                scrollModeRaw = ScrollMode.continuous.rawValue
            }
            gestureSettings = HeadFlowSettings.gestureSettings
        }
        .onChange(of: toggleShortcut) { _, newValue in
            HeadFlowSettings.shortcutToggle = newValue
        }
        .onChange(of: createProfileShortcut) { _, newValue in
            HeadFlowSettings.shortcutCreateProfile = newValue
        }
        .onChange(of: prefsShortcut) { _, newValue in
            HeadFlowSettings.shortcutPreferences = newValue
        }
        .onChange(of: calibrateShortcut) { _, newValue in
            HeadFlowSettings.shortcutCalibrate = newValue
        }
        .onChange(of: cycleModesShortcut) { _, newValue in HeadFlowSettings.shortcutCycleModes = newValue }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                
                // Status indicator with fixed width
                statusIndicator
                
                Spacer()
                
                Image(systemName: "cursorarrow.motionlines")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.linearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("HeadFlow")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
            }
            .padding(.horizontal, spacing)
            .padding(.top, spacing)
            .padding(.bottom, 16)
            
            Divider()
        }
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 8) {
            let info = liveStatusInfo()
            
            Circle()
                .fill(info.color)
                .frame(width: 8, height: 8)
                .shadow(color: info.color.opacity(0.5), radius: 3)
            
            Text(info.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: statusWidth + 40, alignment: .leading)
        }
        .frame(width: statusWidth)
        .padding(.horizontal, 40)
        .padding(.vertical, 6)
        
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: spacing) {
                // Live response card
                liveResponseCard
                
                // System status card
                systemStatusCard
                
                // Headphone device card
                Spacer(minLength: spacing)
            }
            .padding(spacing)
        }
    }
    
    private var liveResponseCard: some View {
        
        return VStack(alignment: .leading, spacing: sectionSpacing) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)
                
                Text("Live Response")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                                
            }
            
            Divider()
            
            // Tilt visualizer
            tiltVisualizerView
                .padding(.vertical, 8)
            
            // Metrics grid with fixed widths
            HStack(spacing: 12) {
                metricCard(
                    icon: "angle",
                    title: "Tilt",
                    value: formattedTilt(live.tiltPercent),
                    color: .blue
                )
                
                metricCard(
                    icon: "speedometer",
                    title: "Velocity",
                    value: formattedVelocity(live.velocityLinesPerSecond),
                    color: .green
                )
                
                metricCard(
                    icon: "gearshape.2",
                    title: "Mode",
                    value: live.mode.displayName,
                    color: .orange
                )
            }
            
            Divider()
            
            // Actions
            HStack(spacing: 12) {
                Button(action: resetGlobalTuningToDefaults) {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Text("Real-time head tracking telemetry")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(spacing)
        .background(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
    
    private var tiltVisualizerView: some View {
        VStack(spacing: 12) {
            // Visual track
            GeometryReader { geo in
                let width = geo.size.width
                let dotRadius: CGFloat = 10
                let halfWidth = width / 2 - dotRadius
                
                let clampedPercent = max(-100.0, min(100.0, live.tiltPercent))
                let offsetX = CGFloat(clampedPercent / 100.0) * halfWidth
                
                let dzFraction = max(
                    0.0,
                    min(1.0, maxTiltDegrees > 0
                        ? deadZoneDegrees / maxTiltDegrees
                        : 0.0)
                )
                let dzWidth = width * CGFloat(dzFraction)
                
                ZStack {
                    // Background track
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                    
                    // Dead zone indicator
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: dzWidth)
                    
                    // Center line
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1.5)
                    
                    // Active region fill
                    if offsetX != 0 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: offsetX > 0 ?
                                    [Color.clear, Color.accentColor.opacity(0.25)] :
                                    [Color.accentColor.opacity(0.25), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: abs(offsetX))
                            .offset(x: offsetX > 0 ? 0 : offsetX)
                    }
                    
                    // Moving dot indicator
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: dotRadius * 2, height: dotRadius * 2)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 4)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: offsetX)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: live.tiltPercent)
                }
            }
            .frame(height: 48)
            
            // Labels
            HStack {
                Label("Down", systemImage: "arrow.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                
                Spacer()
                
                Text("Neutral")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label("Up", systemImage: "arrow.up")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .labelStyle(.trailingIcon)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func metricCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 14)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.06))
        )
    }
    
    private var systemStatusCard: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 20)
                
                Text("System Status")
                    .font(.system(size: 17, weight: .semibold))
            }
            
            Divider()
            
            VStack(spacing: 10) {
                enhancedHeadphoneStatusRow()
                
                statusRow(
                    icon: "figure.walk.motion",
                    title: "Motion Permission",
                    value: status.motionAuthDescription,
                    status: status.motionAuth == .authorized
                )
                
                statusRow(
                    icon: "accessibility",
                    title: "Accessibility",
                    value: status.accessibilityDescription,
                    status: status.accessibility == .enabled
                )
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button(action: {
                    status.refreshAll()
                    lastStatusCheck = Date()
                }) {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button(action: {
                    ScrollEngine.openAccessibilitySettings()
                }) {
                    Label("System Settings", systemImage: "gear")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Spacer()
                
                if let last = lastStatusCheck {
                    Text("Updated \(formattedTime(last))")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(spacing)
        .background(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
    
    private func statusRow(icon: String, title: String, value: String, status: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundStyle(status ? .green : .secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                Text(value)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(status ? .green : .red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.04))
        )
    }
    
    private func enhancedHeadphoneStatusRow() -> some View {
        HStack(spacing: 12) {
            Image(systemName: status.trackingDeviceSymbolName)
                .font(.system(size: iconSize))
                .foregroundStyle(status.headphones == .connected ? .blue : .secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(headphoneDeviceTitle())
                    .font(.system(size: 13, weight: .medium))
                
                HStack(spacing: 6) {
                    Text(status.headphoneDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    if let batteryText = headphoneBatterySummary() {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        
                        Text(batteryText)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: status.headphones == .connected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(status.headphones == .connected ? .green : .red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.04))
        )
    }
    
    // MARK: - Scrolling Tab
    
    private var scrollingTab: some View {
        ScrollView {
            VStack(spacing: spacing) {
                settingsCard(
                    title: "Basic Settings",
                    icon: "slider.horizontal.3"
                ) {
                    Toggle(isOn: $isHeadScrollingEnabled) {
                        Label("Enable head scrolling", systemImage: "play.circle")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .toggleStyle(.switch)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    sliderSetting(
                        title: "Scroll Sensitivity",
                        icon: "gauge.with.needle",
                        value: $scrollSensitivity,
                        range: 0...100,
                        format: "%.0f"
                    )
                    
                    sliderSetting(
                        title: "Max Lines at Full Tilt",
                        icon: "arrow.up.arrow.down",
                        value: $baseLines,
                        range: 0...500,
                        step: 5,
                        format: "%.0f"
                    )
                }
                
                settingsCard(
                                title: "Cursor Control",
                                icon: "cursorarrow"
                            ) {
                                Text("Fine-tune how the head-controlled pointer moves and how big a turn it needs to click.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)

                                Divider()
                                    .padding(.vertical, 4)

                                // Pointer movement
                                sliderSetting(
                                    title: "Pointer Speed",
                                    icon: "cursorarrow.motionlines",
                                    value: $cursorSpeed,
                                    range: 0.5...5.0,
                                    step: 0.1,
                                    format: "%.1fx"
                                )

                                sliderSetting(
                                    title: "Pointer Dead Zone",
                                    icon: "circle.dotted",
                                    value: $cursorDeadZone,
                                    range: 0.0...5.0,
                                    step: 0.1,
                                    format: "%.1f°"
                                )

                                sliderSetting(
                                    title: "Pointer Smoothing",
                                    icon: "waveform.path",
                                    value: $cursorSmoothing,
                                    range: 0.0...1.0,
                                    step: 0.05,
                                    format: "%.2f"
                                )

                                Divider()
                                    .padding(.vertical, 4)

                                // Click gesture yaw thresholds
                                sliderSetting(
                                    title: "Single-Click Turn Angle",
                                    icon: "cursorarrow.click",
                                    value: $singleClickYaw,
                                    range: 5.0...30.0,
                                    step: 1.0,
                                    format: "%.0f°"
                                )

                                sliderSetting(
                                    title: "Double-Click Turn Angle",
                                    icon: "cursorarrow.rays",
                                    value: Binding(
                                        get: { doubleClickYaw },
                                        set: { newValue in
                                            // keep double-click at least 1° above single-click
                                            doubleClickYaw = max(newValue, singleClickYaw + 1.0)
                                        }
                                    ),
                                    range: 8.0...40.0,
                                    step: 1.0,
                                    format: "%.0f°"
                                )

                                sliderSetting(
                                    title: "Click Cooldown",
                                    icon: "timer",
                                    value: $clickCooldown,
                                    range: 0.1...1.5,
                                    step: 0.05,
                                    format: "%.2fs"
                                )

                                Divider()
                                    .padding(.vertical, 4)

                                // Modifier mapping for click + drag
                                let allowedFlags: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

                                CursorModifierPicker(
                                    title: "Click combo",
                                    flags: Binding(
                                        get: {
                                            NSEvent.ModifierFlags(rawValue: UInt(clickRaw))
                                        },
                                        set: { newFlags in
                                            var filtered = newFlags.intersection(allowedFlags)
                                            // Don’t allow “no modifier” for click combo
                                            if filtered.isEmpty {
                                                filtered = [.command] // or just return to keep previous
                                            }
                                            clickRaw = Int(filtered.rawValue)
                                        }
                                    )
                                )

                                CursorModifierPicker(
                                    title: "Extra keys for drag (held with click combo)",
                                    flags: Binding(
                                        get: {
                                            NSEvent.ModifierFlags(rawValue: UInt(dragRaw))
                                        },
                                        set: { newFlags in
                                            let filtered = newFlags.intersection(allowedFlags)
                                            dragRaw = Int(filtered.rawValue)
                                        }
                                    )
                                )


                                Text("Example: Click = ⌘, Drag = ⌘ + ^ (control). You can also choose combos like ⌘+⌥ for click, and ⌘+⌥+^ for drag.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                
                            }
                
                settingsCard(
                    title: "Scroll Behavior",
                    icon: "arrow.up.and.down.text.horizontal"
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scroll Mode")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Picker("Scroll mode", selection: $scrollModeRaw) {
                            ForEach(ScrollMode.allCases) { mode in
                                Text(mode.displayName)
                                    .tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text(scrollMode.shortDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                }
                
                settingsCard(
                    title: "Safety & Pausing",
                    icon: "hand.raised"
                ) {
                    Toggle(isOn: $pauseWhilePointerActive) {
                        Label("Pause while mouse/trackpad is moving", systemImage: "cursorarrow")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .toggleStyle(.switch)
                    
                    Toggle(isOn: $pauseWhileTyping) {
                        Label("Pause while typing", systemImage: "keyboard")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .toggleStyle(.switch)
                    
                    Toggle(isOn: $shiftToPauseEnabled) {
                        Label("Hold ⇧ to temporarily disable", systemImage: "shift")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .toggleStyle(.switch)
                    
                    Toggle(isOn: $dictationPausesHeadFlow) {
                        Label("Pause while dictating", systemImage: "mic")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .toggleStyle(.switch)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    Toggle(isOn: $pauseOnManualScroll) {
                        Label("Pause when I scroll manually", systemImage: "scroll")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .toggleStyle(.switch)
                    
                    if pauseOnManualScroll {
                        sliderSetting(
                            title: "Pause Duration",
                            icon: "timer",
                            value: $manualScrollPauseSeconds,
                            range: 0.1...5.0,
                            format: "%.2fs"
                        )
                    }
                }
                
                settingsCard(
                    title: "Dictation",
                    icon: "mic"
                ) {
                    Toggle(isOn: $dictationAutoCommitEnabled) {
                        Label("Auto-commit after silence", systemImage: "timer.circle")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .toggleStyle(.switch)
                    
                    if dictationAutoCommitEnabled {
                        sliderSetting(
                            title: "Auto-commit silence delay",
                            icon: "timer",
                            value: $dictationAutoCommitDelaySeconds,
                            range: 0.5...10.0,
                            step: 0.5,
                            format: "%.1fs"
                        )

                        Text("When you stop speaking for this long, HeadFlow will insert the last phrase into the focused text field.")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 26)
                    }
                }
                
                Spacer(minLength: spacing)
            }
            .padding(spacing)
        }
    }
    
    // MARK: - Gestures Tab
    
    private var gesturesTab: some View {
        ScrollView {
            VStack(spacing: spacing) {
                settingsCard(
                    title: "Gesture Triggers",
                    icon: "hand.point.up.left"
                ) {
                    Text("Control how hard you need to tilt and how often gestures can repeat")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    sliderSetting(
                        title: "Tilt Threshold",
                        icon: "angle",
                        value: $gestureTiltThresholdDegrees,
                        range: 10...50,
                        format: "%.0f°"
                    )
                    
                    sliderSetting(
                        title: "Cooldown",
                        icon: "timer",
                        value: $gestureCooldownSeconds,
                        range: 0.2...10.0,
                        format: "%.1fs"
                    )
                }
                
                settingsCard(
                    title: "When HeadFlow is ON",
                    icon: "play.circle.fill"
                ) {
                    gestureRow(
                        title: "Tilt / look right",
                        context: .headFlowOn,
                        gesture: .tiltLeft
                    )
                    
                    gestureRow(
                        title: "Tilt / look left",
                        context: .headFlowOn,
                        gesture: .tiltRight
                    )
                }
                
                settingsCard(
                    title: "When HeadFlow is OFF",
                    icon: "pause.circle.fill"
                ) {
                    gestureRow(
                        title: "Tilt / look right",
                        context: .headFlowOff,
                        gesture: .tiltLeft
                    )
                    
                    gestureRow(
                        title: "Tilt / look left",
                        context: .headFlowOff,
                        gesture: .tiltRight
                    )
                }
                
                settingsCard(
                    title: "Custom Shortcuts Bank",
                    icon: "star.circle"
                ) {
                    Text("Define your own shortcuts and reuse them in gesture actions above")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    if gestureSettings.customShortcuts.isEmpty {
                        Text("No custom shortcuts yet")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(gestureSettings.customShortcuts) { custom in
                            customShortcutRow(custom: custom)
                        }
                    }
                    
                    Button(action: addCustomShortcut) {
                        Label("Add Custom Shortcut", systemImage: "plus.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                
                Spacer(minLength: spacing)
            }
            .padding(spacing)
        }
    }
    
    // MARK: - Apps Tab
    
    private var appsTab: some View {
        ScrollView {
            VStack(spacing: spacing) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundStyle(.purple)
                            .frame(width: 20)
                        
                        Text("Per-App Profiles")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    
                    Divider()
                    
                    Text(status.currentProfileSummary)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    Text("Create app-specific profiles from the menu bar while using any app. Each profile can have custom scroll settings.")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .padding(spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                        .fill(Color.purple.opacity(0.08))
                )
                
                if profileManager.profiles.isEmpty {
                    emptyProfilesView
                } else {
                    ForEach(profileManager.profiles) { profile in
                        profileCard(profile: profile)
                    }
                }
                
                Spacer(minLength: spacing)
            }
            .padding(spacing)
        }
    }
    
    private var emptyProfilesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No App Profiles Yet")
                .font(.system(size: 16, weight: .semibold))
            
            Text("Open the HeadFlow menu bar and choose\n'Create profile for current app' while using any application")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
    
    private func profileCard(profile: AppProfile) -> some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.appName)
                        .font(.system(size: 15, weight: .semibold))
                    
                    Text(profile.bundleIdentifier)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(role: .destructive, action: {
                    ProfileManager.shared.removeProfile(profile)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderless)
                .help("Remove this profile")
            }
            
            Divider()
            
            Toggle(isOn: binding(for: profile, keyPath: \.isEnabled)) {
                Label("Enable HeadFlow in this app", systemImage: "power")
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(.switch)
            
            Divider()
                .padding(.vertical, 4)
            
            sliderSetting(
                title: "Scroll Sensitivity",
                icon: "gauge.with.needle",
                value: binding(for: profile, keyPath: \.scrollSensitivity),
                range: 0...100,
                format: "%.0f"
            )
            
            sliderSetting(
                title: "Max Lines at Full Tilt",
                icon: "arrow.up.arrow.down",
                value: binding(for: profile, keyPath: \.baseLines),
                range: 0...500,
                step: 5,
                format: "%.0f"
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    
                    Text("Scroll Mode")
                        .font(.system(size: 13, weight: .medium))
                }
                
                Picker("Scroll mode", selection: binding(for: profile, keyPath: \.scrollModeRaw)) {
                    ForEach(ScrollMode.allCases) { mode in
                        Text(mode.displayName)
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .padding(spacing)
        .background(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
    
    // MARK: - Advanced Tab
    
    private var advancedTab: some View {
        ScrollView {
            VStack(spacing: spacing) {
                settingsCard(
                    title: "Advanced Tuning",
                    icon: "slider.horizontal.3"
                ) {
                    Text("Fine-tune the scrolling physics and response curve")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    sliderSetting(
                        title: "Dead Zone",
                        icon: "circle.dotted",
                        value: $deadZoneDegrees,
                        range: 0...15,
                        step: 0.5,
                        format: "%.1f°"
                    )
                    
                    Text("Small movements within this range won't trigger scrolling")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 26)
                        .padding(.bottom, 8)
                    
                    sliderSetting(
                        title: "Max Tilt for Full Speed",
                        icon: "speedometer",
                        value: $maxTiltDegrees,
                        range: 10...45,
                        step: 1,
                        format: "%.0f°"
                    )
                    
                    Text("Tilt angle needed to reach maximum scroll speed")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 26)
                        .padding(.bottom, 8)
                    
                    sliderSetting(
                        title: "Acceleration",
                        icon: "hare",
                        value: $accelerationFactor,
                        range: 0.5...5.0,
                        format: "%.2fx"
                    )
                    
                    Text("Higher values make scrolling ramp up faster")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 26)
                        .padding(.bottom, 8)
                    
                    sliderSetting(
                        title: "Damping",
                        icon: "tortoise",
                        value: $dampingFactor,
                        range: 0.5...5.0,
                        format: "%.2fx"
                    )
                    
                    Text("Higher values make scrolling stop more quickly")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 26)
                }
                
                Spacer(minLength: spacing)
            }
            .padding(spacing)
        }
    }
    
    // MARK: - Shortcuts Tab
    
    private var shortcutsTab: some View {
        ScrollView {
            VStack(spacing: spacing) {
                settingsCard(
                    title: "Global Keyboard Shortcuts",
                    icon: "keyboard"
                ) {
                    Text("These shortcuts work system-wide, even when other apps are active")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    shortcutRow(
                        icon: "play.circle",
                        title: "Start/Stop HeadFlow",
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
                    // New Shortcut Row

                    shortcutRow(icon: "arrow.triangle.2.circlepath", title: "Cycle Scroll Mode (Cursor/Scroll)", enabled: $globalCycleModesShortcutEnabled, shortcut: $cycleModesShortcut)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 13))
                            .foregroundStyle(.yellow)
                        
                        Text("Tips")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        tipRow(icon: "hand.tap", text: "Click a shortcut pill to record a new key combination")
                        tipRow(icon: "escape", text: "Press Esc while recording to clear the shortcut")
                        tipRow(icon: "power", text: "Disable shortcuts you don't use to avoid conflicts")
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.yellow.opacity(0.08))
                )
                
                Spacer(minLength: spacing)
            }
            .padding(spacing)
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .frame(width: 16)
            
            Text(text)
        }
    }
    
    // MARK: - Reusable Components
    
    private func settingsCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
        }
        .padding(spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
    
    private func sliderSetting(
        title: String,
        icon: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double? = nil,
        format: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                Spacer()
                
                Text(String(format: format, value.wrappedValue))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 50, alignment: .trailing)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            
            if let step = step {
                Slider(value: value, in: range, step: step)
                    .tint(.accentColor)
            } else {
                Slider(value: value, in: range)
                    .tint(.accentColor)
            }
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
                .font(.system(size: 14))
                .foregroundStyle(enabled.wrappedValue ? Color.accentColor : Color.secondary)
                .frame(width: 20)
            
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
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func gestureRow(
        title: String,
        context: GestureContext,
        gesture: GestureType
    ) -> some View {
        let selection = bindingForGesture(context: context, gesture: gesture)
        
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .frame(minWidth: 140, alignment: .leading)
            
            Spacer()
            
            Picker(title, selection: selection) {
                Text("None")
                    .tag(GestureAction.none)
                
                ForEach(HeadFlowActionKind.allCases) { kind in
                    Text("HeadFlow – \(kind.displayName)")
                        .tag(GestureAction.headFlow(kind))
                }
                
                ForEach(StandardShortcutKind.allCases) { kind in
                    Text("macOS – \(kind.displayName)")
                        .tag(GestureAction.standardShortcut(kind))
                }
                
                ForEach(gestureSettings.customShortcuts) { custom in
                    Text("Custom – \(custom.name)")
                        .tag(GestureAction.customShortcut(custom.id))
                }
            }
            .pickerStyle(.menu)
            .frame(width: 280)
        }
        .padding(.vertical, 4)
    }
    
    private func customShortcutRow(custom: CustomShortcut) -> some View {
        HStack(spacing: 12) {
            TextField("Shortcut name", text: bindingForCustomShortcutName(custom))
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
            
            ShortcutRecorderField(shortcut: bindingForCustomShortcutValue(custom))
                .frame(width: 140)
            
            Button(role: .destructive, action: {
                removeCustomShortcut(custom)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Remove this custom shortcut")
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Methods
    
    private func debugHeadphoneState() -> String {
        return """
        Connected: \(headphones.isConnected)
        Kind: \(headphones.kind)
        Name: \(headphones.deviceName ?? "nil")
        """
    }
    
    private func headphoneDeviceTitle() -> String {
        guard status.headphones == .connected else {
            return "Headphones"
        }
        
        // Use the audio device name from CoreAudio
        if !status.audioDeviceName.isEmpty && status.audioDeviceName != "Unknown device" {
            return status.audioDeviceName
        }
        
        return "Headphones"
    }

    private func headphoneDeviceSubtitle() -> String {
        return status.headphoneDescription
    }
    
    private func binding<Value>(
        for profile: AppProfile,
        keyPath: WritableKeyPath<AppProfile, Value>
    ) -> Binding<Value> {
        Binding<Value>(
            get: {
                guard let index = profileManager.profiles.firstIndex(where: { $0.id == profile.id }) else {
                    return profile[keyPath: keyPath]
                }
                return profileManager.profiles[index][keyPath: keyPath]
            },
            set: { newValue in
                guard let index = profileManager.profiles.firstIndex(where: { $0.id == profile.id }) else {
                    return
                }
                profileManager.profiles[index][keyPath: keyPath] = newValue
            }
        )
    }
    
    private func bindingForGesture(
        context: GestureContext,
        gesture: GestureType
    ) -> Binding<GestureAction> {
        Binding<GestureAction>(
            get: {
                if let index = gestureSettings.mappings.firstIndex(where: {
                    $0.context == context && $0.gesture == gesture
                }) {
                    return gestureSettings.mappings[index].action
                } else {
                    return .none
                }
            },
            set: { newValue in
                var settings = gestureSettings
                
                if let index = settings.mappings.firstIndex(where: {
                    $0.context == context && $0.gesture == gesture
                }) {
                    settings.mappings[index].action = newValue
                } else {
                    let mapping = GestureMapping(
                        context: context,
                        gesture: gesture,
                        action: newValue
                    )
                    settings.mappings.append(mapping)
                }
                
                gestureSettings = settings
                HeadFlowSettings.gestureSettings = settings
            }
        )
    }
    
    private func bindingForCustomShortcutName(_ custom: CustomShortcut) -> Binding<String> {
        Binding<String>(
            get: {
                gestureSettings.customShortcuts.first(where: { $0.id == custom.id })?.name
                ?? custom.name
            },
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
            get: {
                gestureSettings.customShortcuts.first(where: { $0.id == custom.id })?.shortcut
                ?? custom.shortcut
            },
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
        let new = CustomShortcut(
            id: UUID(),
            name: "My shortcut",
            shortcut: .none
        )
        settings.customShortcuts.append(new)
        gestureSettings = settings
        HeadFlowSettings.gestureSettings = settings
    }
    
    private func removeCustomShortcut(_ custom: CustomShortcut) {
        var settings = gestureSettings
        
        settings.customShortcuts.removeAll { $0.id == custom.id }
        
        for index in settings.mappings.indices {
            if case .customShortcut(let id) = settings.mappings[index].action,
               id == custom.id {
                settings.mappings[index].action = .none
            }
        }
        
        gestureSettings = settings
        HeadFlowSettings.gestureSettings = settings
    }
    
    private func resetGlobalTuningToDefaults() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            scrollSensitivity = HeadFlowSettings.defaultScrollSensitivity
            baseLines = HeadFlowSettings.defaultBaseLines
            deadZoneDegrees = HeadFlowSettings.defaultDeadZoneDegrees
            maxTiltDegrees = HeadFlowSettings.defaultMaxTiltDegrees
            scrollModeRaw = ScrollMode.continuous.rawValue
            accelerationFactor = HeadFlowSettings.defaultAccelerationFactor
            dampingFactor = HeadFlowSettings.defaultDampingFactor
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func liveStatusInfo() -> (label: String, color: Color) {
        switch live.status {
        case .idle:
            return ("Idle", .secondary)
        case .tracking:
            return ("Tracking", .green)
        case .disconnected:
            return ("Disconnected", .red)
        case .needsSetup:
            return ("Needs Setup", .orange)
        case .pausedPointer:
            return ("Paused – Mouse", .yellow)
        case .pausedTyping:
            return ("Paused – Typing", .yellow)
        case .pausedModifier:
            return ("Paused – Shift", .yellow)
        case .pausedManualScroll:
            return ("Paused – Manual Scroll", .yellow)
        case .pausedDictation:
                return ("Paused – Dictation", .yellow)
        }
    }
    
    private func formattedTilt(_ percent: Double) -> String {
        String(format: "%+.1f%%", percent)
    }
    
    private func formattedVelocity(_ linesPerSecond: Double) -> String {
        String(format: "%.1f l/s", linesPerSecond)
    }
    
    private func headphoneIconName() -> String {
        return status.trackingDeviceSymbolName
    }
    
    private func headphoneStatusText() -> String {
        if !headphones.isConnected {
            return "Not connected"
        }
        return status.headphoneDescription
    }
    
    private func headphoneBatterySummary() -> String? {
        let l = headphones.batteryLeft
        let r = headphones.batteryRight
        let c = headphones.batteryCase
        
        if l == nil, r == nil, c == nil {
            return nil
        }
        
        var parts: [String] = []
        if let l { parts.append("L \(l)%") }
        if let r { parts.append("R \(r)%") }
        if let c { parts.append("Case \(c)%") }
        
        return parts.joined(separator: "  •  ")
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

// MARK: - Shortcut Recorder Field for Custom Shortcuts

struct ShortcutRecorderField: View {
    @Binding var shortcut: KeyboardShortcut
    
    @State private var isRecording = false
    @State private var localMonitor: Any?
    
    var body: some View {
        Button(action: toggleRecording) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(minWidth: 100)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isRecording ? Color.accentColor.opacity(0.08) : Color.clear)
                        )
                )
        }
        .buttonStyle(.plain)
        .onDisappear {
            stopRecording()
        }
    }
    
    private var label: String {
        if isRecording { return "Press keys…" }
        if shortcut.isEmpty { return "Not set" }
        return shortcut.displayString
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event: event)
            return nil
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }
    
    private func handle(event: NSEvent) {
        defer { stopRecording() }
        
        if event.keyCode == 53 {
            shortcut = .none
            return
        }
        
        let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
        guard let first = chars.first else { return }
        
        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
        
        if mods.isEmpty {
            shortcut = .none
            return
        }
        
        shortcut = KeyboardShortcut(key: String(first), modifiers: mods)
    }
}

struct CursorModifierPicker: View {
    let title: String
    @Binding var flags: NSEvent.ModifierFlags

    private let allKeys = CursorModifierKey.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
            HStack(spacing: 12) {
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
                            // Don’t allow “no modifier” for click combo
                            if !newFlags.isEmpty {
                                flags = newFlags
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                }
            }
        }
    }
}


#Preview {
    PreferencesView()
        .frame(width: 750, height: 600)
}
