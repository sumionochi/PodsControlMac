// TextInjectionEngine.swift
import Foundation
import CoreGraphics
import AppKit

enum TextInjectionEngine {

    /// Types text character-by-character using CGEvents, with clipboard fallback
    static func typeText(_ text: String) {
        guard !text.isEmpty else { return }
        
        print("TextInjectionEngine: Starting to type '\(text)'")
        
        // Try direct CGEvent typing first
        if typeTextDirectly(text) {
            print("TextInjectionEngine: ✅ Successfully typed via CGEvents")
            return
        }
        
        // Fallback to clipboard paste for stubborn apps
        print("TextInjectionEngine: Direct typing failed, falling back to clipboard")
        pasteViaClipboard(text)
    }
    
    /// Attempts to type text using CGEvents
    private static func typeTextDirectly(_ text: String) -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("TextInjectionEngine: Failed to create CGEventSource")
            return false
        }

        // Small delay between characters for reliability (in microseconds)
        let delayBetweenChars: useconds_t = 1000 // 1ms
        
        var successCount = 0
        for char in text {
            if typeCharacter(char, source: source) {
                successCount += 1
            }
            usleep(delayBetweenChars)
        }
        
        print("TextInjectionEngine: Typed \(successCount)/\(text.count) characters via CGEvents")
        return successCount > 0
    }
    
    /// Types a single character using CGEvent
    @discardableResult
    private static func typeCharacter(_ character: Character, source: CGEventSource) -> Bool {
        let string = String(character)
        let utf16Array = Array(string.utf16)
        
        guard !utf16Array.isEmpty else { return false }
        
        // Create keyboard events
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            return false
        }
        
        // Set the Unicode string for this character
        utf16Array.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            
            keyDown.keyboardSetUnicodeString(
                stringLength: utf16Array.count,
                unicodeString: base
            )
            keyUp.keyboardSetUnicodeString(
                stringLength: utf16Array.count,
                unicodeString: base
            )
        }
        
        // Post the events
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        
        return true
    }
    
    /// Fallback: paste text via clipboard (Cmd+V)
    private static func pasteViaClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        
        // Save current clipboard content
        let oldContents = pasteboard.string(forType: .string)
        
        // Set our text to clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Small delay to ensure clipboard is set
        usleep(10000) // 10ms
        
        // Simulate Cmd+V
        simulateKeyPress(keyCode: 9, commandKey: true) // V key = 9
        
        print("TextInjectionEngine: ✅ Pasted via clipboard (Cmd+V)")
        
        // Restore old clipboard after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            pasteboard.clearContents()
            if let old = oldContents {
                pasteboard.setString(old, forType: .string)
            }
            print("TextInjectionEngine: Restored original clipboard content")
        }
    }
    
    /// Simulates a key press with optional modifier keys
    private static func simulateKeyPress(keyCode: CGKeyCode, commandKey: Bool = false, shiftKey: Bool = false) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }
        
        var flags: CGEventFlags = []
        if commandKey { flags.insert(.maskCommand) }
        if shiftKey { flags.insert(.maskShift) }
        
        if !flags.isEmpty {
            keyDown.flags = flags
            keyUp.flags = flags
        }
        
        keyDown.post(tap: .cghidEventTap)
        usleep(10000) // 10ms between down and up
        keyUp.post(tap: .cghidEventTap)
    }
}
