import SwiftUI
import AppKit

/// Main preferences UI for HeadFlow.
struct PreferencesView: View {
    // Status from MotionEngine / AppDelegate
    @ObservedObject private var status: HeadFlowStatus

    // Live telemetry for the "Live response" panel
    @ObservedObject private var live = MotionLiveState.shared
    @ObservedObject private var headphones = HeadphoneDeviceState.shared

    // Per-app profiles
    @ObservedObject private var profileManager = ProfileManager.shared

    // Normal settings (global)
    @AppStorage(HeadFlowSettings.keyIsHeadScrollingEnabled)
    private var isHeadScrollingEnabled: Bool = HeadFlowSettings.defaultIsHeadScrollingEnabled

    @AppStorage(HeadFlowSettings.keyScrollSensitivity)
    private var scrollSensitivity: Double = HeadFlowSettings.defaultScrollSensitivity

    @AppStorage(HeadFlowSettings.keyBaseLines)
    private var baseLines: Double = HeadFlowSettings.defaultBaseLines

    // Advanced tuning (global)
    @AppStorage(HeadFlowSettings.keyDeadZoneDegrees)
    private var deadZoneDegrees: Double = HeadFlowSettings.defaultDeadZoneDegrees

    @AppStorage(HeadFlowSettings.keyMaxTiltDegrees)
    private var maxTiltDegrees: Double = HeadFlowSettings.defaultMaxTiltDegrees

    // Scroll mode (stored as raw Int)
    @AppStorage(HeadFlowSettings.keyScrollMode)
    private var scrollModeRaw: Int = HeadFlowSettings.defaultScrollModeRaw

    private var scrollMode: ScrollMode {
        get { ScrollMode(rawValue: scrollModeRaw) ?? .continuous }
        set { scrollModeRaw = newValue.rawValue }
    }

    // Local UI-only state
    @State private var lastStatusCheck: Date? = nil

    // Preset options for max lines: 0, 5, 10, ..., 495, 500
    private let baseLinesOptions: [Double] = Array(stride(from: 0.0, through: 500.0, by: 5.0))

    // Use shared status by default
    init(status: HeadFlowStatus = .shared) {
        self._status = ObservedObject(wrappedValue: status)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 20) {
                Text("HeadFlow Preferences")
                    .font(.title2)
                    .bold()

                // MARK: - Status
                GroupBox("Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Headphones")
                            Spacer()
                            Text(status.headphoneDescription)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Motion permission")
                            Spacer()
                            Text(status.motionAuthDescription)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Accessibility")
                            Spacer()
                            Text(status.accessibilityDescription)
                                .foregroundStyle(.secondary)
                        }

                        Text("Overall: \(status.overallSummary)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if let last = lastStatusCheck {
                            Text("Last checked: \(formattedTime(last))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Button("Re-check status") {
                            status.refreshAll()
                            lastStatusCheck = Date()
                        }
                        .buttonStyle(.link)

                        Text("Note: Changes to Accessibility permission may require restarting HeadFlow.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // MARK: - Live response
                GroupBox("Live response") {
                    VStack(alignment: .leading, spacing: 12) {
                        let info = liveStatusInfo()

                        HStack {
                            Text("Live response")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(info.color)
                                    .frame(width: 8, height: 8)
                                Text(info.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("Head tilt mapped to scroll speed in real time.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        // Tilt track with dead zone and moving dot
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
                                Capsule()
                                    .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1)

                                // Dead zone band
                                Capsule()
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(width: dzWidth)

                                // Center line
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.4))
                                    .frame(width: 1)

                                // Current tilt dot
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: dotRadius * 2, height: dotRadius * 2)
                                    .offset(x: offsetX)
                                    .shadow(radius: 1)
                                    .animation(.easeOut(duration: 0.08), value: live.tiltPercent)
                            }
                        }
                        .frame(height: 44)

                        // Numeric summary
                        HStack(spacing: 12) {
                            liveMetricBox(
                                title: "Tilt",
                                value: formattedTilt(live.tiltPercent),
                                subtitle: "Tilt vs neutral"
                            )
                            liveMetricBox(
                                title: "Velocity",
                                value: formattedVelocity(live.velocityLinesPerSecond),
                                subtitle: "Scroll speed (lines/s)"
                            )
                            liveMetricBox(
                                title: "Mode",
                                value: live.mode.displayName,
                                subtitle: info.label
                            )
                        }

                        // ⬇️ ADD THIS BLOCK
                        Button("Reset global tuning to defaults") {
                            resetGlobalTuningToDefaults()
                        }
                        .font(.caption)
                        .buttonStyle(.link)
                        // ⬆️ ADD THIS BLOCK

                        Divider()
                            .padding(.vertical, 4)

                        // Headphone device card
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: headphoneIconName())
                                .font(.system(size: 24))
                                .foregroundColor(headphones.isConnected ? .accentColor : .secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(headphones.deviceName ?? "No device connected")
                                    .font(.subheadline)

                                Text(headphoneStatusText())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if let batteryText = headphoneBatterySummary() {
                                Text(batteryText)
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // MARK: - Normal settings (global)
                GroupBox("Normal settings") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $isHeadScrollingEnabled) {
                            Text("Enable head scrolling")
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Scroll sensitivity")
                                Spacer()
                                Text("\(Int(scrollSensitivity))")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: $scrollSensitivity, in: 0...100)
                        }

                        // Picker for 0–500 max lines (every 5)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Max scroll lines at full tilt")
                                Spacer()
                                Text("\(Int(baseLines.rounded()))")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }

                            let selection = Binding<Double>(
                                get: { nearestBaseLinesOption(for: baseLines) },
                                set: { newValue in baseLines = newValue }
                            )

                            Picker("Max scroll lines at full tilt", selection: selection) {
                                ForEach(baseLinesOptions, id: \.self) { value in
                                    Text("\(Int(value))")
                                        .tag(value)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }

                // MARK: - Scroll behavior (global)
                GroupBox("Scroll behavior") {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Scroll mode", selection: $scrollModeRaw) {
                            ForEach(ScrollMode.allCases) { mode in
                                Text(mode.displayName)
                                    .tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(scrollMode.shortDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Per-app behavior
                GroupBox("Per-app behavior") {
                    VStack(alignment: .leading, spacing: 10) {
                        // Live summary of which app/profile is active
                        Text(status.currentProfileSummary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("To create a profile: while you are in Safari, Xcode, etc., open the HeadFlow menu in the menu bar and choose “Create profile for current app”. Profiles will then appear here for editing.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if profileManager.profiles.isEmpty {
                            Text("No app-specific profiles yet. Global settings will be used everywhere.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        } else {
                            ForEach(profileManager.profiles) { profile in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(profile.appName)
                                            .font(.headline)
                                        Spacer()
                                        Text(profile.bundleIdentifier)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    // isEnabled binding
                                    Toggle("Enable HeadFlow in this app",
                                           isOn: binding(for: profile, keyPath: \.isEnabled))

                                    // Per-app sensitivity
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Scroll sensitivity")
                                            Spacer()
                                            Text("\(Int(binding(for: profile, keyPath: \.scrollSensitivity).wrappedValue))")
                                                .monospacedDigit()
                                                .foregroundStyle(.secondary)
                                        }
                                        Slider(
                                            value: binding(for: profile, keyPath: \.scrollSensitivity),
                                            in: 0...100
                                        )
                                    }

                                    // Per-app max lines via Picker (0–500, every 5)
                                    VStack(alignment: .leading, spacing: 4) {
                                        let rawBaseLinesBinding = binding(for: profile, keyPath: \.baseLines)

                                        HStack {
                                            Text("Max lines at full tilt")
                                            Spacer()
                                            Text("\(Int(rawBaseLinesBinding.wrappedValue.rounded()))")
                                                .monospacedDigit()
                                                .foregroundStyle(.secondary)
                                        }

                                        let selection = Binding<Double>(
                                            get: { nearestBaseLinesOption(for: rawBaseLinesBinding.wrappedValue) },
                                            set: { newValue in rawBaseLinesBinding.wrappedValue = newValue }
                                        )

                                        Picker("Max lines at full tilt", selection: selection) {
                                            ForEach(baseLinesOptions, id: \.self) { value in
                                                Text("\(Int(value))")
                                                    .tag(value)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }

                                    // Per-app scroll mode
                                    Picker("Scroll mode",
                                           selection: binding(for: profile, keyPath: \.scrollModeRaw)) {
                                        ForEach(ScrollMode.allCases) { mode in
                                            Text(mode.displayName)
                                                .tag(mode.rawValue)
                                        }
                                    }
                                    .labelsHidden()

                                    HStack {
                                        Spacer()
                                        Button(role: .destructive) {
                                            ProfileManager.shared.removeProfile(profile)
                                        } label: {
                                            Text("Remove profile")
                                        }
                                    }

                                    Divider()
                                }
                                .padding(.top, 6)
                            }
                        }
                    }
                }

                // MARK: - Focused / advanced tuning (global)
                GroupBox("Focused tuning (global)") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Dead zone (° around neutral)")
                                Spacer()
                                Text(String(format: "%.1f°", deadZoneDegrees))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: $deadZoneDegrees, in: 0...15, step: 0.5)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Max tilt for full speed (°)")
                                Spacer()
                                Text(String(format: "%.0f°", maxTiltDegrees))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: $maxTiltDegrees, in: 10...45, step: 1)
                        }
                        
                        
                    }
                }

                Divider()

                // Troubleshooting
                VStack(alignment: .leading, spacing: 8) {
                    Text("Troubleshooting")
                        .font(.headline)

                    Button("Open Accessibility Settings…") {
                        ScrollEngine.openAccessibilitySettings()
                    }
                    .buttonStyle(.link)

                    Text("If scrolling does not work, make sure HeadFlow is enabled in Accessibility and that compatible headphones are connected.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(20)
        }
        .frame(
            minWidth: 380,
            idealWidth: 460,
            maxWidth: .infinity,
            minHeight: 260,
            idealHeight: 420,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .onAppear {
            // Keep status fresh
            status.refreshAll()
            lastStatusCheck = Date()

            // Fix any invalid scrollModeRaw (e.g. old "step" = 1) to a valid value.
            let validModes = Set(ScrollMode.allCases.map { $0.rawValue })
            if !validModes.contains(scrollModeRaw) {
                scrollModeRaw = ScrollMode.continuous.rawValue
            }
        }
    }

    // MARK: - Helpers

    /// Build a Binding to a specific property of a specific profile, using its id.
    private func binding<Value>(
        for profile: AppProfile,
        keyPath: WritableKeyPath<AppProfile, Value>
    ) -> Binding<Value> {
        Binding<Value>(
            get: {
                guard let index = profileManager.profiles.firstIndex(where: { $0.id == profile.id }) else {
                    // If profile disappeared, just return the old value.
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

    /// Snap an arbitrary baseLines value to the nearest preset option.
    private func nearestBaseLinesOption(for value: Double) -> Double {
        guard let nearest = baseLinesOptions.min(by: { abs($0 - value) < abs($1 - value) }) else {
            return value
        }
        return nearest
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func resetGlobalTuningToDefaults() {
        scrollSensitivity = HeadFlowSettings.defaultScrollSensitivity
        baseLines = HeadFlowSettings.defaultBaseLines
        deadZoneDegrees = HeadFlowSettings.defaultDeadZoneDegrees
        maxTiltDegrees = HeadFlowSettings.defaultMaxTiltDegrees
        scrollModeRaw = ScrollMode.continuous.rawValue
    }

    // Live response helpers

    private func liveStatusInfo() -> (label: String, color: Color) {
        switch live.status {
        case .idle:
            return ("Idle", .secondary)
        case .tracking:
            return ("Tracking", .green)
        case .disconnected:
            return ("Disconnected", .red)
        case .needsSetup:
            return ("Needs setup", .orange)
        }
    }

    private func formattedTilt(_ percent: Double) -> String {
        String(format: "%.1f %%", percent)
    }

    private func formattedVelocity(_ linesPerSecond: Double) -> String {
        String(format: "%.2f L/s", linesPerSecond)
    }

    @ViewBuilder
    private func liveMetricBox(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospacedDigit()
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.06))
        )
    }

    // Headphone card helpers

    private func headphoneIconName() -> String {
        switch headphones.kind {
        case .airPods:
            return "airpodspro"      // SF Symbol (macOS 13+)
        case .beats:
            return "beats.headphones"
        case .other, .none:
            return "headphones"
        }
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

        return parts.joined(separator: "  ")
    }
}

#Preview {
    PreferencesView()
}
