import Foundation
import AppKit

/// Tracks recent mouse / trackpad movement so MotionEngine
/// can pause scrolling while the user is actively pointing.
final class PointerActivityMonitor {

    static let shared = PointerActivityMonitor()

    private var monitor: Any?
    private var lastEventTime: CFAbsoluteTime = 0

    private init() {}

    func start() {
        guard monitor == nil else { return }

        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        ) { [weak self] _ in
            self?.lastEventTime = CFAbsoluteTimeGetCurrent()
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    /// Returns true if pointer moved within the last `threshold` seconds.
    func isRecentlyActive(threshold: CFTimeInterval) -> Bool {
        guard lastEventTime > 0 else { return false }
        let now = CFAbsoluteTimeGetCurrent()
        return (now - lastEventTime) < threshold
    }
}
