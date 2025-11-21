import Foundation
import AppKit

/// Tracks recent mouse / trackpad movement so MotionEngine
/// can pause scrolling while the user is actively pointing.
final class PointerActivityMonitor {

    static let shared = PointerActivityMonitor()

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var lastEventTime: CFAbsoluteTime = 0

    private init() {}

    func start() {
        // Global monitor: pointer movement in other apps
        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.mouseMoved,
                           .leftMouseDragged,
                           .rightMouseDragged,
                           .otherMouseDragged]
            ) { [weak self] _ in
                self?.lastEventTime = CFAbsoluteTimeGetCurrent()
            }
        }

        // Local monitor: pointer movement inside HeadFlow (e.g. Preferences)
        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.mouseMoved,
                           .leftMouseDragged,
                           .rightMouseDragged,
                           .otherMouseDragged]
            ) { [weak self] event in
                self?.lastEventTime = CFAbsoluteTimeGetCurrent()
                return event    // important: let the event pass through
            }
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        globalMonitor = nil

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        localMonitor = nil
    }

    /// Returns true if pointer moved within the last `threshold` seconds.
    func isRecentlyActive(threshold: CFTimeInterval) -> Bool {
        guard lastEventTime > 0 else { return false }
        let now = CFAbsoluteTimeGetCurrent()
        return (now - lastEventTime) < threshold
    }
}
