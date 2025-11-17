import SwiftUI
import AppKit

/// Main preferences UI for HeadFlow.
/// Uses @AppStorage to persist settings in UserDefaults.
struct PreferencesView: View {
    // Stored automatically in UserDefaults with these keys.
    @AppStorage("isHeadScrollingEnabled") private var isHeadScrollingEnabled: Bool = true
    @AppStorage("scrollSensitivity") private var scrollSensitivity: Double = 50.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("HeadFlow Preferences")
                    .font(.headline)

                Toggle("Enable head scrolling", isOn: $isHeadScrollingEnabled)

                // Sensitivity slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Scroll sensitivity")
                        Spacer()
                        Text("\(Int(scrollSensitivity))")
                            .monospacedDigit()
                    }

                    Slider(value: $scrollSensitivity, in: 0...100)
                }

                Divider()
                    .padding(.vertical, 4)

                // Debug & test section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Debug / test")
                        .font(.subheadline)
                        .bold()

                    HStack {
                        Button("Test scroll up") {
                            let lines = computedLines()
                            ScrollEngine.scrollUp(lines: lines)
                        }

                        Button("Test scroll down") {
                            let lines = computedLines()
                            ScrollEngine.scrollDown(lines: lines)
                        }
                    }

                    // NEW: auto-scroll test button
                    Button("Run 3s auto-scroll test") {
                        let lines = computedLines()
                        ScrollEngine.startAutoScrollDownTest(
                            duration: 3.0,
                            interval: 0.1,
                            linesPerTick: lines,
                            initialDelay: 1.0
                        )
                    }

                    Button("Open Accessibility Settings…") {
                        ScrollEngine.openAccessibilitySettings()
                    }
                    .buttonStyle(.link)

                    Text("""
                    Tip 1: When this window is frontmost, scroll events will move \
                    this content.

                    Tip 2: For the auto-scroll test, click the button, then quickly \
                    switch to Safari/Notes/PDF with ⌘Tab and make sure your mouse is \
                    over a scrollable area. The page should scroll for a few seconds.
                    """)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                    // Extra filler text to make sure the ScrollView can actually scroll
                    ForEach(0..<20) { i in
                        Text("Scrollable debug line \(i + 1)")
                            .font(.footnote)
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .frame(width: 380, height: 280)
    }

    /// Map 0–100 sensitivity slider to roughly 1–10 scroll lines.
    private func computedLines() -> Int32 {
        let clamped = max(0.0, min(100.0, scrollSensitivity))
        let normalized = clamped / 100.0          // 0...1
        let lines = 1 + normalized * 9.0          // 1...10
        return Int32(lines.rounded())
    }
}

#Preview {
    PreferencesView()
}
