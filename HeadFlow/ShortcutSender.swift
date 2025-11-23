// ShortcutSender.swift
import Foundation
import AppKit
import CoreGraphics

/// Sends a KeyboardShortcut to the frontmost app using CGEvent.
/// Requires Accessibility permission for full control.
enum ShortcutSender {

    static func send(_ shortcut: KeyboardShortcut) {
        // Don't try to send an empty shortcut.
        guard !shortcut.isEmpty else { return }

        // Map key string to a virtual key code.
        guard let keyCode = KeyCodeMapper.keyCode(for: shortcut.key) else {
            print("ShortcutSender: unsupported key '\(shortcut.key)'")
            return
        }

        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("ShortcutSender: failed to create CGEventSource")
            return
        }

        let flags = cgFlags(from: shortcut.modifiers)

        // Key down
        if let eventDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: keyCode,
            keyDown: true
        ) {
            eventDown.flags = flags
            eventDown.post(tap: .cghidEventTap)
        }

        // Key up
        if let eventUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: keyCode,
            keyDown: false
        ) {
            eventUp.flags = flags
            eventUp.post(tap: .cghidEventTap)
        }
    }

    /// Convert NSEvent.ModifierFlags into CGEventFlags for CGEvent.
    private static func cgFlags(from modifiers: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: CGEventFlags = []

        if modifiers.contains(.command) {
            flags.insert(.maskCommand)
        }
        if modifiers.contains(.option) {
            flags.insert(.maskAlternate)
        }
        if modifiers.contains(.control) {
            flags.insert(.maskControl)
        }
        if modifiers.contains(.shift) {
            flags.insert(.maskShift)
        }

        return flags
    }
}
