//ManualScrollMonitor
import Foundation
import AppKit
import CoreGraphics

/// Listens for global scrollWheel events and notifies ManualScrollPauseController
/// when the user scrolls with mouse/trackpad (not HeadFlow).
final class ManualScrollMonitor {

    static let shared = ManualScrollMonitor()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {}

    func start() {
        guard eventTap == nil else { return }

        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, _ in
                // Only care about scrollWheel events.
                guard type == .scrollWheel else {
                    return Unmanaged.passUnretained(event)
                }

                // Ignore our own synthetic events.
                if !ScrollEngine.isHeadFlowEvent(event) {
                    ManualScrollPauseController.shared.registerManualScroll()
                }

                // For a listen-only tap, just pass the event through unchanged.
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        )

        guard let eventTap else {
            print("ManualScrollMonitor: failed to create event tap – no permission?")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        runLoopSource = source

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("ManualScrollMonitor: started")
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil

        print("ManualScrollMonitor: stopped")
    }
}
