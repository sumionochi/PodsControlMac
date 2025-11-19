import SwiftUI
import Cocoa
import CoreMotion
import ApplicationServices
import AppKit

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

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var preferencesWindowController: PreferencesWindowController?

    // Menu items we update dynamically
    private var headScrollingMenuItem: NSMenuItem?
    private var summaryMenuItem: NSMenuItem?

    @available(macOS 14.0, *)
    private lazy var motionEngine = MotionEngine()

    func applicationDidFinishLaunching(_ notification: Notification) {
        HeadFlowSettings.registerDefaults()
        HeadFlowStatus.shared.refreshAll()
        HeadFlowStatus.shared.startObservingFrontmostApp()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "HF"
        }

        let menu = NSMenu()
        menu.delegate = self

        // Dynamic summary item (“HeadFlow is running – currently focused on …”)
        let summaryItem = NSMenuItem(
            title: HeadFlowStatus.shared.currentProfileSummary,
            action: nil,
            keyEquivalent: ""
        )
        summaryItem.isEnabled = false
        menu.addItem(summaryItem)
        self.summaryMenuItem = summaryItem

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
            title: "Calibrate head position",
            action: #selector(calibrateHeadPosition),
            keyEquivalent: ""
        )
        calibrateItem.target = self
        menu.addItem(calibrateItem)

        // Per-app profile
        let profileItem = NSMenuItem(
            title: "Create profile for current app",
            action: #selector(createProfileForCurrentApp),
            keyEquivalent: "p"
        )
        profileItem.target = self
        menu.addItem(profileItem)

        // Preferences
        let prefsItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(
            title: "Quit HeadFlow",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu

        if #available(macOS 14.0, *) {
            motionEngine.start()
        } else {
            print("HeadFlow: headphone motion requires macOS 14 or later.")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if #available(macOS 14.0, *) {
            motionEngine.stop()
        }
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        // Keep summary + toggle in sync with current state
        summaryMenuItem?.title = HeadFlowStatus.shared.currentProfileSummary
        updateHeadScrollingMenuItem()
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

    @objc func toggleHeadScrolling() {
        HeadFlowSettings.isHeadScrollingEnabled.toggle()
        updateHeadScrollingMenuItem()
        print("HeadFlow: head scrolling is now \(HeadFlowSettings.isHeadScrollingEnabled ? "ON" : "OFF")")
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Helpers

    private func headScrollingMenuTitle() -> String {
        HeadFlowSettings.isHeadScrollingEnabled
            ? "Head scrolling: On"
            : "Head scrolling: Off"
    }

    private func updateHeadScrollingMenuItem() {
        guard let item = headScrollingMenuItem else { return }
        item.title = headScrollingMenuTitle()
        item.state = HeadFlowSettings.isHeadScrollingEnabled ? .on : .off
    }
}
