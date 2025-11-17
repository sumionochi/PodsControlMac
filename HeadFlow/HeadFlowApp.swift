import SwiftUI
import Cocoa

@main
struct HeadFlowMacApp: App {
    // Used an app delegate to manage the status bar item
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // No visible settings window yet
        }
    }
}

class PreferencesWindowController: NSWindowController {
    convenience init() {
        // Created the SwiftUI view
        let preferencesView = PreferencesView()

        // Wrapped it in an NSHostingView
        let hostingView = NSHostingView(rootView: preferencesView)

        // Created the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 240),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "HeadFlow Preferences"
        window.contentView = hostingView
        window.center()

        self.init(window: window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Created a status bar item with variable length
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "HF" // Temporary label; later we can use an icon
        }

        // Built the menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "HeadFlow Running",
                                action: nil,
                                keyEquivalent: ""))
        
        let prefsItem = NSMenuItem(title: "Preferences…",
                                   action: #selector(openPreferences),
                                   keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit HeadFlow",
                                action: #selector(quit),
                                keyEquivalent: "q"))

        statusItem?.menu = menu
    }
    
    @objc func openPreferences() {
        if let controller = preferencesWindowController {
            
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
        } else {
            // Created and showed for the first time
            let controller = PreferencesWindowController()
            preferencesWindowController = controller
            controller.showWindow(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
}
