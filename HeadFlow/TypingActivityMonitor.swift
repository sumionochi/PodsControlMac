import Foundation
import AppKit

/// Tracks recent key presses so MotionEngine can pause while typing.
final class TypingActivityMonitor {

    static let shared = TypingActivityMonitor()

    private var monitor: Any?
    private var lastKeyTime: CFAbsoluteTime = 0

    private init() {}

    func start() {
        guard monitor == nil else { return }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            // Optionally ignore modifier-only keys if you want:
            if event.charactersIgnoringModifiers?.isEmpty == false {
                self?.lastKeyTime = CFAbsoluteTimeGetCurrent()
            }
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    func isRecentlyActive(threshold: CFTimeInterval) -> Bool {
        guard lastKeyTime > 0 else { return false }
        let now = CFAbsoluteTimeGetCurrent()
        return (now - lastKeyTime) < threshold
    }
}
