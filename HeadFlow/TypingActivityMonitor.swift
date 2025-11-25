//TypingActivityMonitor
import Foundation
import AppKit

/// Tracks recent key presses so MotionEngine can pause while typing.
final class TypingActivityMonitor {

    static let shared = TypingActivityMonitor()

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var lastKeyTime: CFAbsoluteTime = 0

    private init() {}

    func start() {
        // Global: typing in other apps
        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                if event.charactersIgnoringModifiers?.isEmpty == false {
                    self?.lastKeyTime = CFAbsoluteTimeGetCurrent()
                }
            }
        }
        
        // Local: typing inside HeadFlow app
        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                if event.charactersIgnoringModifiers?.isEmpty == false {
                    self?.lastKeyTime = CFAbsoluteTimeGetCurrent()
                }
                return event
            }
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            self.globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            self.localMonitor = nil
        }
    }

    func isRecentlyActive(threshold: CFTimeInterval) -> Bool {
        guard lastKeyTime > 0 else { return false }
        let now = CFAbsoluteTimeGetCurrent()
        return (now - lastKeyTime) < threshold
    }
}
