//KeyboardShortcut
import Foundation
import AppKit

/// Simple representation of a 1-key shortcut (e.g. ⇧⌘H).
struct KeyboardShortcut: Codable, Equatable, Hashable {
    /// lowercased charactersIgnoringModifiers (single char)
    var key: String
    /// NSEvent.ModifierFlags.rawValue for ⌘ ⇧ ⌥ ^ etc.
    var modifiersRaw: UInt

    init(key: String, modifiers: NSEvent.ModifierFlags) {
        self.key = key.lowercased()
        let filtered = modifiers.intersection([.command, .shift, .option, .control])
        self.modifiersRaw = filtered.rawValue
    }

    static let none = KeyboardShortcut(key: "", modifiers: [])

    var modifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiersRaw)
    }

    var isEmpty: Bool {
        key.isEmpty
    }

    /// Does this shortcut match the given keyDown event?
    func matches(event: NSEvent) -> Bool {
        guard !isEmpty else { return false }

        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
        guard let first = chars.first else { return false }

        return String(first) == key && flags == modifiers
    }

    /// Nice human-readable string like "⇧⌘H" or "⌘," or "None".
    var displayString: String {
        if isEmpty { return "None" }

        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.shift)   { parts.append("⇧") }
        if modifiers.contains(.option)  { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("^") }

        let label: String
        switch key {
        case ",":
            label = ","
        case ".":
            label = "."
        case ";":
            label = ";"
        case "/":
            label = "/"
        case " ":
            label = "Space"
        default:
            label = key.uppercased()
        }

        parts.append(label)
        return parts.joined()
    }
}
