// ShortcutFactory.swift
import Foundation
import AppKit

/// Helpers to locate shortcuts for standard/custom IDs.
enum ShortcutFactory {

    /// Returns the KeyboardShortcut for a StandardShortcutKind.
    static func standardShortcut(for kind: StandardShortcutKind) -> KeyboardShortcut? {
        switch kind {
        case .copy:
            return KeyboardShortcut(key: "c", modifiers: [.command])

        case .paste:
            return KeyboardShortcut(key: "v", modifiers: [.command])

        case .cut:
            return KeyboardShortcut(key: "x", modifiers: [.command])

        case .undo:
            return KeyboardShortcut(key: "z", modifiers: [.command])

        case .redo:
            return KeyboardShortcut(key: "z", modifiers: [.command, .shift])

        case .quitApp:
            return KeyboardShortcut(key: "q", modifiers: [.command])

        case .closeWindow:
            return KeyboardShortcut(key: "w", modifiers: [.command])

        case .switchApps:
            // ⌘ + Tab
            return KeyboardShortcut(key: "\t", modifiers: [.command])

        case .spotlight:
            // ⌘ + Space
            return KeyboardShortcut(key: " ", modifiers: [.command])

        case .screenshotFull:
            // ⇧⌘3
            return KeyboardShortcut(key: "3", modifiers: [.command, .shift])

        case .screenshotSelection:
            // ⇧⌘4
            return KeyboardShortcut(key: "4", modifiers: [.command, .shift])

        case .screenshotToolbar:
            // ⇧⌘5
            return KeyboardShortcut(key: "5", modifiers: [.command, .shift])
        }
    }

    /// Returns the KeyboardShortcut for a given CustomShortcut id from bank.
    static func customShortcut(with id: UUID) -> KeyboardShortcut? {
        let settings = HeadFlowSettings.gestureSettings
        return settings.customShortcuts.first(where: { $0.id == id })?.shortcut
    }
}
