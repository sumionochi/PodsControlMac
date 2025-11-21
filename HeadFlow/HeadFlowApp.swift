import SwiftUI
import Cocoa
import CoreMotion
import ApplicationServices
import AppKit

protocol GlobalShortcutHandler: AnyObject {
    func handleGlobalToggleHeadFlow()
    func handleGlobalCreateProfile()
    func handleGlobalOpenPreferences()
    func handleGlobalCalibrate()
}

@main
struct HeadFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class PreferencesWindowController: NSWindowController {
    convenience init() {
        let preferencesView = PreferencesView()
        let hostingView = NSHostingView(rootView: preferencesView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "HeadFlow Preferences"
        window.contentView = hostingView
        window.center()
        window.minSize = NSSize(width: 380, height: 220)

        self.init(window: window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, GlobalShortcutHandler {
    var statusItem: NSStatusItem?
    var preferencesWindowController: PreferencesWindowController?

    // Menu items we update dynamically
    private var headScrollingMenuItem: NSMenuItem?
    private var calibrateMenuItem: NSMenuItem?
    private var createProfileMenuItem: NSMenuItem?
    private var preferencesMenuItem: NSMenuItem?

    private var launchAtLoginMenuItem: NSMenuItem?
    private var summaryMenuItem: NSMenuItem?
    private var headphoneStatusMenuItem: NSMenuItem?

    @available(macOS 14.0, *)
    private lazy var motionEngine = MotionEngine()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make sure defaults exist even if user never opened Preferences.
        HeadFlowSettings.registerDefaults()
        HeadFlowStatus.shared.refreshAll()
        HeadFlowStatus.shared.startObservingFrontmostApp()
        PointerActivityMonitor.shared.start()
        TypingActivityMonitor.shared.start()
        GlobalShortcutMonitor.shared.handler = self
        GlobalShortcutMonitor.shared.start()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "HF"
        }

        let menu = NSMenu()
        menu.delegate = self

        // 🔹 Dynamic summary item (“HeadFlow is running – currently focused on …”)
        let summaryItem = NSMenuItem(
            title: HeadFlowStatus.shared.currentProfileSummary,
            action: nil,
            keyEquivalent: ""
        )
        summaryItem.isEnabled = false
        menu.addItem(summaryItem)
        self.summaryMenuItem = summaryItem
        
        // 🔹 New: Headphones status line
        let headphoneItem = NSMenuItem(
            title: headphoneStatusTitle(),
            action: nil,
            keyEquivalent: ""
        )
        headphoneItem.isEnabled = false
        menu.addItem(headphoneItem)
        self.headphoneStatusMenuItem = headphoneItem

        menu.addItem(NSMenuItem.separator())

        // Head scrolling toggle item
        let toggleItem = NSMenuItem(
            title: headScrollingMenuTitle(),
            action: #selector(toggleHeadScrolling),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = HeadFlowSettings.isHeadScrollingEnabled ? .on : .off
        menu.addItem(toggleItem)
        self.headScrollingMenuItem = toggleItem

        // Calibrate item
        let calibrateItem = NSMenuItem(
            title: calibrateMenuTitle(),
            action: #selector(calibrateHeadPosition),
            keyEquivalent: ""
        )
        calibrateItem.target = self
        menu.addItem(calibrateItem)
        self.calibrateMenuItem = calibrateItem

        // Create per-app profile for whatever app is currently frontmost
        let profileItem = NSMenuItem(
            title: createProfileMenuTitle(),
            action: #selector(createProfileForCurrentApp),
            keyEquivalent: ""
        )
        profileItem.target = self
        menu.addItem(profileItem)
        self.createProfileMenuItem = profileItem

        // --- NEW: Launch at Login submenu (A1) ---
        let launchAtLoginItem = buildLaunchAtLoginMenu()
        menu.addItem(launchAtLoginItem)
        self.launchAtLoginMenuItem = launchAtLoginItem
        updateLaunchAtLoginMenuChecks()
        // -----------------------------------------

        // Preferences
        let prefsItem = NSMenuItem(
            title: preferencesMenuTitle(),
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.keyEquivalentModifierMask = [.command] // keep standard ⌘,
        prefsItem.target = self
        menu.addItem(prefsItem)
        self.preferencesMenuItem = prefsItem

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(
            title: "Quit HeadFlow",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu

        // Start motion engine
        if #available(macOS 14.0, *) {
            motionEngine.start()
        } else {
            print("HeadFlow: headphone motion requires macOS 14 or later.")
        }

        // Ensure system login item registration matches our stored setting.
        LaunchAtLoginController.syncFromSettingsToSystem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if #available(macOS 14.0, *) {
            motionEngine.stop()
        }
        GlobalShortcutMonitor.shared.stop()
    }

    // MARK: - Menu delegate

    /// Called right before the menu is shown – keep the summary fresh.
    func menuNeedsUpdate(_ menu: NSMenu) {
        summaryMenuItem?.title = HeadFlowStatus.shared.currentProfileSummary
        headphoneStatusMenuItem?.title = headphoneStatusTitle()

        // This updates Start/Stop HeadFlow title + checkmark
        updateHeadScrollingMenuItem()

        createProfileMenuItem?.title = createProfileMenuTitle()
        calibrateMenuItem?.title = calibrateMenuTitle()
        preferencesMenuItem?.title = preferencesMenuTitle()
    }

    // MARK: - Menu actions

    @objc func openPreferences() {
        if let controller = preferencesWindowController {
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
        } else {
            let controller = PreferencesWindowController()
            preferencesWindowController = controller
            controller.showWindow(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func createProfileForCurrentApp() {
        ProfileManager.shared.addOrUpdateProfileForFrontmostApp()
    }

    @objc func calibrateHeadPosition() {
        if #available(macOS 14.0, *) {
            motionEngine.calibrateNeutral()
        }
    }

    /// Toggle global head scrolling on/off from the menu.
    @objc func toggleHeadScrolling() {
        HeadFlowSettings.isHeadScrollingEnabled.toggle()
        updateHeadScrollingMenuItem()
        print("HeadFlow: head scrolling is now \(HeadFlowSettings.isHeadScrollingEnabled ? "ON" : "OFF")")
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
    
    // MARK: - GlobalShortcutHandler

    func handleGlobalToggleHeadFlow() {
        toggleHeadScrolling()
    }

    func handleGlobalCreateProfile() {
        createProfileForCurrentApp()
    }

    func handleGlobalOpenPreferences() {
        openPreferences()
    }
    
    func handleGlobalCalibrate() {
        calibrateHeadPosition()
    }

    // MARK: - Launch at Login submenu

    /// Builds the "Launch at Login" submenu with two choices.
    private func buildLaunchAtLoginMenu() -> NSMenuItem {
        let submenu = NSMenu()

        for mode in LaunchAtLoginMode.allCases {
            let item = NSMenuItem(
                title: mode.menuTitle,
                action: #selector(changeLaunchAtLoginMode(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = mode.rawValue
            submenu.addItem(item)
        }

        let parent = NSMenuItem(
            title: "Launch at Login",
            action: nil,
            keyEquivalent: ""
        )
        parent.submenu = submenu
        return parent
    }

    /// User clicked one of the "Launch at Login" options.
    @objc private func changeLaunchAtLoginMode(_ sender: NSMenuItem) {
        guard let newMode = LaunchAtLoginMode(rawValue: sender.tag) else { return }
        HeadFlowSettings.launchAtLoginMode = newMode
        updateLaunchAtLoginMenuChecks()
        LaunchAtLoginController.syncFromSettingsToSystem()
    }

    /// Checkmark the currently selected launch mode.
    private func updateLaunchAtLoginMenuChecks() {
        guard let submenu = launchAtLoginMenuItem?.submenu else { return }
        let currentRaw = HeadFlowSettings.launchAtLoginMode.rawValue

        for item in submenu.items {
            item.state = (item.tag == currentRaw) ? .on : .off
        }
    }

    // MARK: - Helpers
    
    private func headScrollingMenuTitle() -> String {
        let base = HeadFlowSettings.isHeadScrollingEnabled
            ? "Stop HeadFlow"
            : "Start HeadFlow"

        if let label = shortcutLabel(
            for: HeadFlowSettings.shortcutToggle,
            enabled: HeadFlowSettings.globalToggleShortcutEnabled
        ) {
            return "\(base) (\(label))"
        }

        return base
    }
    
    private func createProfileMenuTitle() -> String {
        let base = "Create profile for current app"

        if let label = shortcutLabel(
            for: HeadFlowSettings.shortcutCreateProfile,
            enabled: HeadFlowSettings.globalCreateProfileShortcutEnabled
        ) {
            return "\(base) (\(label))"
        }

        return base
    }

    private func calibrateMenuTitle() -> String {
        let base = "Calibrate head position"

        if let label = shortcutLabel(
            for: HeadFlowSettings.shortcutCalibrate,
            enabled: HeadFlowSettings.globalCalibrateShortcutEnabled
        ) {
            return "\(base) (\(label))"
        }

        return base
    }

    private func preferencesMenuTitle() -> String {
        let base = "Preferences…"

        if let label = shortcutLabel(
            for: HeadFlowSettings.shortcutPreferences,
            enabled: HeadFlowSettings.globalPreferencesShortcutEnabled
        ) {
            return "\(base) (\(label))"
        }

        return base
    }
    
    private func headphoneStatusTitle() -> String {
        "Headphones: \(HeadFlowStatus.shared.headphoneDescription)"
    }
    
    private func updateHeadScrollingMenuItem() {
        guard let item = headScrollingMenuItem else { return }
        item.title = headScrollingMenuTitle()
        item.state = HeadFlowSettings.isHeadScrollingEnabled ? .on : .off
    }
    
    private func shortcutLabel(for shortcut: KeyboardShortcut,
                               enabled: Bool) -> String? {
        guard enabled, !shortcut.isEmpty else { return nil }
        return shortcut.displayString
    }

}
