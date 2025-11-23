// CustomShortcut.swift
import Foundation

/// User-defined reusable shortcuts, stored in a bank.
/// E.g. "New tab in browser (⌘T)".
struct CustomShortcut: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var shortcut: KeyboardShortcut
}
