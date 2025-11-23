// StandardShortcuts.swift
import Foundation

/// Well-known macOS shortcuts we want to expose as presets.
enum StandardShortcutKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case copy
    case paste
    case cut
    case undo
    case redo
    case quitApp
    case closeWindow
    case switchApps
    case spotlight
    case screenshotFull
    case screenshotSelection
    case screenshotToolbar   // optional, can be unused for now

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .copy:               return "Copy (⌘C)"
        case .paste:              return "Paste (⌘V)"
        case .cut:                return "Cut (⌘X)"
        case .undo:               return "Undo (⌘Z)"
        case .redo:               return "Redo (⇧⌘Z)"
        case .quitApp:            return "Quit app (⌘Q)"
        case .closeWindow:        return "Close window/tab (⌘W)"
        case .switchApps:         return "Switch apps (⌘Tab)"
        case .spotlight:          return "Spotlight (⌘Space)"
        case .screenshotFull:     return "Screenshot full screen (⇧⌘3)"
        case .screenshotSelection:return "Screenshot selection (⇧⌘4)"
        case .screenshotToolbar:  return "Screenshot toolbar (⇧⌘5)"
        }
    }
}
