import SwiftUI
import AppKit

/// Little pill that lets the user record a keyboard shortcut.
/// Used from PreferencesView's "Keyboard shortcuts" section.
struct ShortcutRecorderButton: View {
    @Binding var shortcut: KeyboardShortcut

    @State private var isRecording = false
    @State private var localMonitor: Any?

    var body: some View {
        Button(action: toggleRecording) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.secondary,
                                lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onDisappear {
            stopRecording()
        }
    }

    private var label: String {
        if isRecording { return "Press keys…" }
        if shortcut.isEmpty { return "Set shortcut" }
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
            return nil // swallow so it doesn't type into text fields
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

        // Esc to clear
        if event.keyCode == 53 {
            shortcut = .none
            return
        }

        let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
        guard let first = chars.first else { return }

        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])

        // Require at least one modifier so plain letters don't hijack everything
        if mods.isEmpty {
            shortcut = .none
            return
        }

        shortcut = KeyboardShortcut(key: String(first), modifiers: mods)
    }
}
