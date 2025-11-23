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

// Notification fired when the Welcome / permission flow is completed.
extension Notification.Name {
    static let headFlowSetupCompleted = Notification.Name("HeadFlowSetupCompleted")
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, GlobalShortcutHandler {
    var statusItem: NSStatusItem?
    var preferencesWindowController: PreferencesWindowController?
    var welcomeWindowController: WelcomeWindowController?
    
    // Flag to prevent double-starting services
    private var servicesStarted = false

    // Menu items we update dynamically
    private var headScrollingMenuItem: NSMenuItem?
    private var calibrateMenuItem: NSMenuItem?
    private var createProfileMenuItem: NSMenuItem?
    private var preferencesMenuItem: NSMenuItem?

    private var launchAtLoginMenuItem: NSMenuItem?
    private var summaryMenuItem: NSMenuItem?
    private var headphoneStatusMenuItem: NSMenuItem?
    private var deviceMenuItem: NSMenuItem?

    @available(macOS 14.0, *)
    private lazy var motionEngine = MotionEngine()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Basic setup (defaults)
        HeadFlowSettings.registerDefaults()
        
        // 2. Build menu bar UI immediately so the app feels alive
        setupMenu()
        
        // 3. Observe "setup completed" from the Welcome / permission flow
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startServices),
            name: .headFlowSetupCompleted,
            object: nil
        )

        // 4. Decide whether to show Welcome or start services immediately
        if !HeadFlowSettings.hasSeenWelcome {
            print("HeadFlow: First run detected. Showing Welcome Window.")
            showWelcomeWindow()
        } else {
            print("HeadFlow: Welcome already seen. Starting services immediately.")
            startServices()
        }
        
        // 5. Gesture-driven UI observers (Preferences / Calibrate)
        setupNotificationObservers()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if #available(macOS 14.0, *) {
            motionEngine.stop()
        }
        GlobalShortcutMonitor.shared.stop()
        ManualScrollMonitor.shared.stop()
    }
    
    // MARK: - Startup Logic
    
    /// Called once when we’re ready to actually run everything:
    /// status observers, monitors, motion engine, global shortcuts, etc.
    @objc func startServices() {
        guard !servicesStarted else { return }
        servicesStarted = true
        
        print("HeadFlow: Initializing core services...")

        // Status & observers
        HeadFlowStatus.shared.refreshAll()
        HeadFlowStatus.shared.startObservingFrontmostApp()
        HeadFlowStatus.shared.startObservingAudioDevice()
        
        // Monitors
        PointerActivityMonitor.shared.start()
        TypingActivityMonitor.shared.start()
        ManualScrollMonitor.shared.start()
        
        // Global shortcuts
        GlobalShortcutMonitor.shared.handler = self
        GlobalShortcutMonitor.shared.start()
        
        // Login item sync
        LaunchAtLoginController.syncFromSettingsToSystem()
        
        // Motion engine (also shows Motion permission if not already granted)
        if #available(macOS 14.0, *) {
            motionEngine.start()
        } else {
            print("HeadFlow: Headphone motion requires macOS 14 or later.")
        }
        
        // Menubar key equivalents
        refreshMenuShortcuts()
    }
    
    private func setupNotificationObservers() {
        // These notifications are posted from GestureDispatcher (coming from MotionEngine queue),
        // so we keep the handlers taking Notification and hop back to the main thread.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCalibrateRequested(_:)),
            name: .headFlowCalibrateRequested,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTogglePreferencesRequested(_:)),
            name: .headFlowTogglePreferencesRequested,
            object: nil
        )
    }

    // MARK: - Menu Setup

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "HF"
        }

        let menu = NSMenu()
        menu.delegate = self

        // Summary: “HeadFlow is running – currently focused on …”
        let summaryItem = NSMenuItem(
            title: HeadFlowStatus.shared.currentProfileSummary,
            action: nil,
            keyEquivalent: ""
        )
        summaryItem.isEnabled = false
        menu.addItem(summaryItem)
        self.summaryMenuItem = summaryItem
        
        // Device info line: "Head tracking: AirPods Pro" + icon
        let deviceItem = NSMenuItem(
            title: HeadFlowStatus.shared.trackingDeviceMenuSummary,
            action: nil,
            keyEquivalent: ""
        )
        deviceItem.isEnabled = false
        if #available(macOS 11.0, *) {
            deviceItem.image = NSImage(
                systemSymbolName: HeadFlowStatus.shared.trackingDeviceSymbolName,
                accessibilityDescription: nil
            )
        }
        menu.addItem(deviceItem)
        self.deviceMenuItem = deviceItem

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

        // Launch at Login submenu
        let launchAtLoginItem = buildLaunchAtLoginMenu()
        menu.addItem(launchAtLoginItem)
        self.launchAtLoginMenuItem = launchAtLoginItem
        updateLaunchAtLoginMenuChecks()
        
        // Show welcome again (for debugging / re-viewing intro)
        let welcomeItem = NSMenuItem(
            title: "Show Welcome Message",
            action: #selector(showWelcomeMessageFromMenu),
            keyEquivalent: ""
        )
        welcomeItem.target = self
        menu.addItem(welcomeItem)

        // Preferences
        let prefsItem = NSMenuItem(
            title: preferencesMenuTitle(),
            action: #selector(openPreferences),
            keyEquivalent: ""
        )
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
    }

    // MARK: - Menu delegate

    /// Called right before the menu is shown – keep the summary fresh.
    func menuNeedsUpdate(_ menu: NSMenu) {
        summaryMenuItem?.title = HeadFlowStatus.shared.currentProfileSummary
        if let deviceItem = deviceMenuItem {
            deviceItem.title = HeadFlowStatus.shared.trackingDeviceMenuSummary
            if #available(macOS 11.0, *) {
                deviceItem.image = NSImage(
                    systemSymbolName: HeadFlowStatus.shared.trackingDeviceSymbolName,
                    accessibilityDescription: nil
                )
            }
        }
        headphoneStatusMenuItem?.title = headphoneStatusTitle()

        // This updates Start/Stop HeadFlow title + checkmark
        updateHeadScrollingMenuItem()

        createProfileMenuItem?.title = createProfileMenuTitle()
        calibrateMenuItem?.title = calibrateMenuTitle()
        preferencesMenuItem?.title = preferencesMenuTitle()
        refreshMenuShortcuts()
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
        // Only calibrate if services are running (motion engine exists)
        if servicesStarted, #available(macOS 14.0, *) {
            motionEngine.calibrateNeutral()
        } else {
            // If user tries to calibrate before setup, maybe show welcome or just ignore
            if !servicesStarted { showWelcomeWindow() }
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
    
    // MARK: - Gesture-driven notifications

    /// Called when GestureDispatcher posts `.headFlowCalibrateRequested`.
    @objc private func handleCalibrateRequested(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.calibrateHeadPosition()
        }
    }

    /// Called when GestureDispatcher posts `.headFlowTogglePreferencesRequested`.
    @objc private func handleTogglePreferencesRequested(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.openPreferences()
        }
    }
    
    @objc func openPreferencesFromWelcome(_ sender: Any?) {
        openPreferences()
        closeWelcomeWindow()
    }

    @objc func closeWelcomeFromView(_ sender: Any?) {
        closeWelcomeWindow()
    }

    @objc func showWelcomeMessageFromMenu() {
        showWelcomeWindow()
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
    
    // MARK: - Welcome window

    func showWelcomeWindow() {
        if welcomeWindowController == nil {
            welcomeWindowController = WelcomeWindowController()
        }
        welcomeWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeWelcomeWindow() {
        welcomeWindowController?.close()
        welcomeWindowController = nil
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
        HeadFlowSettings.isHeadScrollingEnabled
            ? "Stop HeadFlow"
            : "Start HeadFlow"
    }
    
    private func createProfileMenuTitle() -> String {
        "Create profile for current app"
    }

    private func calibrateMenuTitle() -> String {
        "Calibrate head position"
    }

    private func preferencesMenuTitle() -> String {
        "Preferences…"
    }
    
    private func applyShortcut(_ shortcut: KeyboardShortcut,
                               enabled: Bool,
                               to item: NSMenuItem) {
        // If the shortcut is disabled or empty, clear the menu key equivalent.
        guard enabled, !shortcut.isEmpty else {
            item.keyEquivalent = ""
            item.keyEquivalentModifierMask = []
            return
        }

        // Key: we assume single-character like "h", "j", "," etc.
        item.keyEquivalent = shortcut.key.lowercased()

        // Modifiers: map your stored modifiers to NSEvent.ModifierFlags
        var flags: NSEvent.ModifierFlags = []
        if shortcut.modifiers.contains(.command) { flags.insert(.command) }
        if shortcut.modifiers.contains(.option)  { flags.insert(.option) }
        if shortcut.modifiers.contains(.control) { flags.insert(.control) }
        if shortcut.modifiers.contains(.shift)   { flags.insert(.shift) }

        item.keyEquivalentModifierMask = flags
    }
    
    private func refreshMenuShortcuts() {
        if let item = headScrollingMenuItem {
            applyShortcut(
                HeadFlowSettings.shortcutToggle,
                enabled: HeadFlowSettings.globalToggleShortcutEnabled,
                to: item
            )
        }

        if let item = createProfileMenuItem {
            applyShortcut(
                HeadFlowSettings.shortcutCreateProfile,
                enabled: HeadFlowSettings.globalCreateProfileShortcutEnabled,
                to: item
            )
        }

        if let item = calibrateMenuItem {
            applyShortcut(
                HeadFlowSettings.shortcutCalibrate,
                enabled: HeadFlowSettings.globalCalibrateShortcutEnabled,
                to: item
            )
        }

        if let item = preferencesMenuItem {
            applyShortcut(
                HeadFlowSettings.shortcutPreferences,
                enabled: HeadFlowSettings.globalPreferencesShortcutEnabled,
                to: item
            )
        }
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
