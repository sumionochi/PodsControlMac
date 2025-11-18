import SwiftUI
import Cocoa
import CoreMotion

@main
struct HeadFlowMacApp: App {
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

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var preferencesWindowController: PreferencesWindowController?

    @available(macOS 14.0, *)
    private lazy var motionEngine = MotionEngine()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register default settings so everything has sane values
        // even before the user opens Preferences.
        HeadFlowSettings.registerDefaults()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "HF"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "HeadFlow Running",
            action: nil,
            keyEquivalent: ""
        ))

        let calibrateItem = NSMenuItem(
            title: "Calibrate head position",
            action: #selector(calibrateHeadPosition),
            keyEquivalent: ""
        )
        calibrateItem.target = self
        menu.addItem(calibrateItem)

        let prefsItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

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

    @objc func calibrateHeadPosition() {
        if #available(macOS 14.0, *) {
            motionEngine.calibrateNeutral()
        }
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
