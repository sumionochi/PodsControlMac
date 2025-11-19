import SwiftUI
import AppKit

/// Main preferences UI for HeadFlow.
struct PreferencesView: View {
    // Status from MotionEngine / AppDelegate
    @ObservedObject private var status: HeadFlowStatus

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

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Max scroll lines per update")
                                Spacer()
                                Text("\(Int(baseLines.rounded()))")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: $baseLines, in: 1...20, step: 1)
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

                                    // Per-app max lines
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Max lines per update")
                                            Spacer()
                                            Text("\(Int(binding(for: profile, keyPath: \.baseLines).wrappedValue.rounded()))")
                                                .monospacedDigit()
                                                .foregroundStyle(.secondary)
                                        }
                                        Slider(
                                            value: binding(for: profile, keyPath: \.baseLines),
                                            in: 1...20,
                                            step: 1
                                        )
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
            status.refreshAll()
            lastStatusCheck = Date()
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

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    PreferencesView()
}
