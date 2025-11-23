// GestureDispatcher.swift
import Foundation
import AppKit

/// Central brain: given (context, gesture) it looks up the configured action
/// and executes it (HeadFlow internal action or a keyboard shortcut).
final class GestureDispatcher {

    static let shared = GestureDispatcher()

    private init() {}

    // MARK: - Public entry point

    func handle(gesture: GestureType, context: GestureContext) {
        let settings = HeadFlowSettings.gestureSettings

        // Find mapping for this (context, gesture).
        guard let mapping = settings.mappings.first(where: {
            $0.context == context && $0.gesture == gesture
        }) else {
            // No mapping configured – nothing to do.
            return
        }

        let action = mapping.action

        // 🔹 VERY IMPORTANT:
        // All actions can touch AppKit (NSWorkspace, windows) or ObservableObjects
        // (ProfileManager.profiles, AppStorage-backed settings).
        // Always hop to the main queue to avoid "Publishing changes from
        // background threads is not allowed" and AppKit threading issues.
        DispatchQueue.main.async { [weak self] in
            self?.execute(action: action)
        }
    }

    // MARK: - Action execution

    private func execute(action: GestureAction) {
        switch action {
        case .none:
            return

        case .headFlow(let kind):
            executeHeadFlowAction(kind)

        case .standardShortcut(let kind):
            if let shortcut = ShortcutFactory.standardShortcut(for: kind) {
                ShortcutSender.send(shortcut)
            }

        case .customShortcut(let id):
            if let shortcut = ShortcutFactory.customShortcut(with: id) {
                ShortcutSender.send(shortcut)
            }
        }
    }

    // MARK: - HeadFlow actions

    private func executeHeadFlowAction(_ kind: HeadFlowActionKind) {
        switch kind {
        case .togglePerAppProfile:
            togglePerAppProfileForCurrentApp()

        case .showHidePreferences:
            togglePreferencesWindow()

        case .recalibrateNeutral:
            postNotification(.headFlowCalibrateRequested)

        case .toggleHeadFlowScrolling:
            toggleHeadScrollingEnabled()

        case .increaseAcceleration:
            bumpAcceleration(by: +0.1)

        case .decreaseAcceleration:
            bumpAcceleration(by: -0.1)

        case .increaseDamping:
            bumpDamping(by: +0.1)

        case .decreaseDamping:
            bumpDamping(by: -0.1)

        case .increaseDeadZone:
            bumpDeadZone(by: +0.5)

        case .decreaseDeadZone:
            bumpDeadZone(by: -0.5)

        case .increaseMaxTilt:
            bumpMaxTilt(by: +1.0)

        case .decreaseMaxTilt:
            bumpMaxTilt(by: -1.0)

        case .increaseMaxScrollLines:
            bumpBaseLines(by: +5.0)

        case .decreaseMaxScrollLines:
            bumpBaseLines(by: -5.0)

        case .increaseSensitivity:
            bumpSensitivity(by: +5.0)

        case .decreaseSensitivity:
            bumpSensitivity(by: -5.0)
        }
    }

    // MARK: - HeadFlow toggles / helpers

    private func toggleHeadScrollingEnabled() {
        HeadFlowSettings.isHeadScrollingEnabled.toggle()
        print("GestureDispatcher: isHeadScrollingEnabled = \(HeadFlowSettings.isHeadScrollingEnabled)")
    }

    private func togglePerAppProfileForCurrentApp() {
        // For now this is a very simple flip of an "enabled" flag:
        // If a profile exists for the frontmost app, toggle its isEnabled.
        // If not, create one (enabled).
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else {
            return
        }

        let manager = ProfileManager.shared

        if let profile = manager.profile(for: bundleID),
           let index = manager.profiles.firstIndex(where: { $0.id == profile.id }) {
            // Toggle in-place on main thread (safe for @Published).
            manager.profiles[index].isEnabled.toggle()
            print("GestureDispatcher: per-app profile for \(bundleID) isEnabled = \(manager.profiles[index].isEnabled)")
        } else {
            // No profile yet → create one, using existing helper.
            manager.addOrUpdateProfileForFrontmostApp()
            print("GestureDispatcher: created per-app profile for \(bundleID)")
        }
    }

    private func togglePreferencesWindow() {
        // We don't have direct access to AppDelegate here.
        // Use NotificationCenter and let AppDelegate respond.
        postNotification(.headFlowTogglePreferencesRequested)
    }

    private func postNotification(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }

    // MARK: - Tuning bump helpers

    private func bumpAcceleration(by delta: Double) {
        let current = HeadFlowSettings.accelerationFactor
        let clamped = max(0.5, min(5.0, current + delta))
        HeadFlowSettings.accelerationFactor = clamped
        print("GestureDispatcher: accelerationFactor = \(clamped)")
    }

    private func bumpDamping(by delta: Double) {
        let current = HeadFlowSettings.dampingFactor
        let clamped = max(0.5, min(5.0, current + delta))
        HeadFlowSettings.dampingFactor = clamped
        print("GestureDispatcher: dampingFactor = \(clamped)")
    }

    private func bumpDeadZone(by delta: Double) {
        let current = HeadFlowSettings.deadZoneDegrees
        let clamped = max(0.0, min(15.0, current + delta))
        HeadFlowSettings.deadZoneDegrees = clamped
        print("GestureDispatcher: deadZoneDegrees = \(clamped)")
    }

    private func bumpMaxTilt(by delta: Double) {
        let current = HeadFlowSettings.maxTiltDegrees
        let clamped = max(10.0, min(45.0, current + delta))
        HeadFlowSettings.maxTiltDegrees = clamped
        print("GestureDispatcher: maxTiltDegrees = \(clamped)")
    }

    private func bumpBaseLines(by delta: Double) {
        let current = HeadFlowSettings.baseLinesValue
        let clamped = max(0.0, min(500.0, current + delta))
        HeadFlowSettings.baseLinesValue = clamped
        print("GestureDispatcher: baseLinesValue = \(clamped)")
    }

    private func bumpSensitivity(by delta: Double) {
        let current = HeadFlowSettings.scrollSensitivity
        let clamped = max(0.0, min(100.0, current + delta))
        HeadFlowSettings.scrollSensitivity = clamped
        print("GestureDispatcher: scrollSensitivity = \(clamped)")
    }
}
