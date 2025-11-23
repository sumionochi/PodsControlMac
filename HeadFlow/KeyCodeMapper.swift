// KeyCodeMapper.swift
import Foundation
import CoreGraphics

/// Maps simple key strings to macOS virtual key codes.
/// This table covers letters, digits, space, and tab that we use for shortcuts.
enum KeyCodeMapper {

    static func keyCode(for key: String) -> CGKeyCode? {
        guard let first = key.lowercased().first else {
            return nil
        }

        switch first {
        // Letters (US keyboard layout)
        case "a": return 0
        case "s": return 1
        case "d": return 2
        case "f": return 3
        case "h": return 4
        case "g": return 5
        case "z": return 6
        case "x": return 7
        case "c": return 8
        case "v": return 9
        // 10 is non-letter
        case "b": return 11
        case "q": return 12
        case "w": return 13
        case "e": return 14
        case "r": return 15
        case "y": return 16
        case "t": return 17

        // Numbers (top row)
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "6": return 22
        case "5": return 23
        case "=": return 24
        case "9": return 25
        case "7": return 26
        case "-": return 27
        case "8": return 28
        case "0": return 29

        // Space + Tab
        case " ":
            return 49        // Space
        case "\t":
            return 48        // Tab

        default:
            return nil
        }
    }
}
