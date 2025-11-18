import SwiftUI
import AppKit

/// Main preferences UI for HeadFlow.
struct PreferencesView: View {
    @AppStorage(HeadFlowSettings.keyIsHeadScrollingEnabled)
    private var isHeadScrollingEnabled: Bool = true

    @AppStorage(HeadFlowSettings.keyScrollSensitivity)
    private var scrollSensitivity: Double = 50.0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text("HeadFlow Preferences")
                .font(.title2)
                .bold()

            // Enable toggle
            Toggle(isOn: $isHeadScrollingEnabled) {
                Text("Enable head scrolling")
            }

            // Sensitivity slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Scroll sensitivity")
                    Spacer()
                    Text("\(Int(scrollSensitivity))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Slider(value: $scrollSensitivity, in: 0...100)
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

                Text("If scrolling does not work, make sure HeadFlow is enabled in Accessibility.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true) // prevents truncation
            }

            Spacer()
        }
        .padding(20)
        // Responsive frame: gives a reasonable minimum, but lets the window grow
        .frame(
            minWidth: 380,
            idealWidth: 420,
            maxWidth: .infinity,
            minHeight: 220,
            idealHeight: 260,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }

    /// Maps 0–100 sensitivity slider to roughly 1–10 scroll lines.
    /// (To be used later by the motion engine.)
    private func computedLines() -> Int32 {
        let clamped = max(0.0, min(100.0, scrollSensitivity))
        let normalized = clamped / 100.0
        let lines = 1 + normalized * 9.0
        return Int32(lines.rounded())
    }
}

#Preview {
    PreferencesView()
}
