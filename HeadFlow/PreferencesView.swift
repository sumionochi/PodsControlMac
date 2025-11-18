import SwiftUI
import AppKit

/// Main preferences UI for HeadFlow.
struct PreferencesView: View {
    // Normal settings
    @AppStorage(HeadFlowSettings.keyIsHeadScrollingEnabled)
    private var isHeadScrollingEnabled: Bool = HeadFlowSettings.defaultIsHeadScrollingEnabled

    @AppStorage(HeadFlowSettings.keyScrollSensitivity)
    private var scrollSensitivity: Double = HeadFlowSettings.defaultScrollSensitivity

    @AppStorage(HeadFlowSettings.keyBaseLines)
    private var baseLines: Double = HeadFlowSettings.defaultBaseLines

    // Advanced tuning
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

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("HeadFlow Preferences")
                .font(.title2)
                .bold()

            // MARK: - Normal settings
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

            // MARK: - Scroll behavior
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

            // MARK: - Focused / advanced tuning
            GroupBox("Focused tuning") {
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

            // Troubleshooting section
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

            Spacer()
        }
        .padding(20)
        .frame(
            minWidth: 380,
            idealWidth: 440,
            maxWidth: .infinity,
            minHeight: 260,
            idealHeight: 340,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }
}

#Preview {
    PreferencesView()
}
