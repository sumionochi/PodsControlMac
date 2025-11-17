import Foundation
import CoreGraphics
import AppKit

/// ScrollEngine is responsible for sending synthetic scroll events
/// to the system. All methods are static so you don't need to
/// instantiate it anywhere.
struct ScrollEngine {

    /// Timer used for the short auto-scroll test.
    /// We keep a reference so the timer is not deallocated early.
    private static var autoScrollTimer: Timer?

    /// Sends a vertical scroll event with the given number of "lines".
    ///
    /// - Parameter lines: Positive = scroll up, Negative = scroll down.
    static func scrollLines(_ lines: Int32) {
        // Create an event source that represents the HID system state.
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("ScrollEngine: Failed to create CGEventSource")
            return
        }

        // Create a line-based scroll wheel event.
        guard let event = CGEvent(
            scrollWheelEvent2Source: source,
            units: .line,
            wheelCount: 1,      // vertical axis only
            wheel1: lines,
            wheel2: 0,
            wheel3: 0
        ) else {
            print("ScrollEngine: Failed to create scroll CGEvent")
            return
        }

        // Post to the global HID event tap so whichever app is frontmost
        // (and has the mouse over a scrollable area) receives the event.
        event.post(tap: .cghidEventTap)
        print("ScrollEngine: posted scroll event with lines=\(lines)")
    }

    /// Convenience helper: scroll down by a number of lines.
    /// On macOS, negative values scroll down for most setups.
    static func scrollDown(lines: Int32) {
        scrollLines(-lines)
    }

    /// Convenience helper: scroll up by a number of lines.
    static func scrollUp(lines: Int32) {
        scrollLines(lines)
    }

    /// Opens System Settings at Privacy & Security → Accessibility
    /// so the user can enable control for this app.
    static func openAccessibilitySettings() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) {
            NSWorkspace.shared.open(url)
        }
    }

    /// Starts a short automatic scroll-down test.
    ///
    /// Usage for the user:
    /// 1. Click the "Auto-scroll test" button in Preferences.
    /// 2. Within the delay (e.g. 1 second), press ⌘Tab to Safari/Notes/PDF
    ///    and make sure the mouse is over a scrollable area.
    /// 3. The page should scroll for a few seconds on its own.
    ///
    /// - Parameters:
    ///   - duration: How long the test should run, in seconds.
    ///   - interval: Time between individual scroll events.
    ///   - linesPerTick: How many scroll lines to send per tick.
    ///   - initialDelay: Delay before the first scroll, to give the
    ///                   user time to switch to the target app.
    static func startAutoScrollDownTest(
        duration: TimeInterval = 3.0,
        interval: TimeInterval = 0.1,
        linesPerTick: Int32 = 3,
        initialDelay: TimeInterval = 1.0
    ) {
        // Cancel any previous test.
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil

        guard duration > 0, interval > 0 else {
            print("ScrollEngine: auto-scroll not started (invalid duration/interval)")
            return
        }

        let totalTicks = Int(duration / interval)
        print("""
        ScrollEngine: scheduling auto-scroll test \
        (duration=\(duration)s, interval=\(interval)s, ticks=\(totalTicks), delay=\(initialDelay)s)
        """)

        // Start after a small delay so the user can switch apps.
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            var ticks = 0

            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                if ticks >= totalTicks {
                    timer.invalidate()
                    autoScrollTimer = nil
                    print("ScrollEngine: auto-scroll test finished")
                } else {
                    scrollDown(lines: linesPerTick)
                    ticks += 1
                }
            }

            autoScrollTimer = timer
            RunLoop.main.add(timer, forMode: .common)

            print("ScrollEngine: auto-scroll test started")
        }
    }
}
