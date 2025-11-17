import SwiftUI

struct PreferencesView: View {
    // These are stored in UserDefaults automatically
    @AppStorage("isHeadScrollingEnabled") private var isHeadScrollingEnabled: Bool = true
    @AppStorage("scrollSensitivity") private var scrollSensitivity: Double = 50.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HeadFlow Preferences")
                .font(.headline)

            Toggle("Enable head scrolling", isOn: $isHeadScrollingEnabled)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Scroll sensitivity")
                    Spacer()
                    Text("\(Int(scrollSensitivity))")
                        .monospacedDigit()
                }

                Slider(value: $scrollSensitivity, in: 0...100)
            }

            Spacer()

            Text("Settings are saved automatically.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 360, height: 200)
    }
}

#Preview {
    PreferencesView()
}
