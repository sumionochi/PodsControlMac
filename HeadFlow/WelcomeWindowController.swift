//WelcomeWindowController
import AppKit
import SwiftUI

class WelcomeWindowController: NSWindowController {
    convenience init() {
        let welcomeView = WelcomeView()
        let hostingView = NSHostingView(rootView: welcomeView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Welcome to HeadFlow"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
    }
}
