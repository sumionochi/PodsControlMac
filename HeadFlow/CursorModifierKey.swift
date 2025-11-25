import Foundation
import AppKit

enum CursorModifierKey: Int, CaseIterable, Identifiable, Codable {
    case command = 0
    case option  = 1
    case control = 2
    case shift   = 3

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .command: return "⌘ Command"
        case .option:  return "⌥ Option"
        case .control: return "^ Control"
        case .shift:   return "⇧ Shift"
        }
    }

    var eventFlag: NSEvent.ModifierFlags {
        switch self {
        case .command: return .command
        case .option:  return .option
        case .control: return .control
        case .shift:   return .shift
        }
    }
}
