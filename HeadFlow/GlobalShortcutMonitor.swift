//GlobalShortcutMonitor
import Foundation
import AppKit

/// Listens for global keyDown events and triggers HeadFlow shortcuts.
/// Fixed combos:
/// - ⇧⌘H  → toggle HeadFlow
/// - ⇧⌘P  → create profile for current app
/// - ⇧⌘,  → open Preferences
final class GlobalShortcutMonitor {

    static let shared = GlobalShortcutMonitor()

    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    weak var handler: GlobalShortcutHandler?

    private init() {}

    func start() {
        // Global: when other apps are frontmost
        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                self?.handle(event: event)
            }
        }

        // Local: when HeadFlow is the active app (Preferences, etc.)
        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                guard let self = self else { return event }
                self.handle(event: event)
                return event    // don't swallow; let the app also see the key
            }
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func handle(event: NSEvent) {
        guard let handler else { return }

        // Start/Stop HeadFlow
        if HeadFlowSettings.globalToggleShortcutEnabled,
           HeadFlowSettings.shortcutToggle.matches(event: event) {

            DispatchQueue.main.async {
                handler.handleGlobalToggleHeadFlow()
            }
            return
        }

        // Create profile for current app
        if HeadFlowSettings.globalCreateProfileShortcutEnabled,
           HeadFlowSettings.shortcutCreateProfile.matches(event: event) {

            DispatchQueue.main.async {
                handler.handleGlobalCreateProfile()
            }
            return
        }

        // Open preferences
        if HeadFlowSettings.globalPreferencesShortcutEnabled,
           HeadFlowSettings.shortcutPreferences.matches(event: event) {

            DispatchQueue.main.async {
                handler.handleGlobalOpenPreferences()
            }
            return
        }

        // Calibrate head position
        if HeadFlowSettings.globalCalibrateShortcutEnabled,
           HeadFlowSettings.shortcutCalibrate.matches(event: event) {

            DispatchQueue.main.async {
                handler.handleGlobalCalibrate()
            }
            return
        }
        
        // Cycle scroll mode
        if HeadFlowSettings.globalCycleModesShortcutEnabled,
           HeadFlowSettings.shortcutCycleModes.matches(event: event) {

            DispatchQueue.main.async {
                handler.handleGlobalCycleModes()
            }
            return
        }

    }

}
