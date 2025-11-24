//  ModeNotificationUtil.swift

import Foundation
import AppKit

/// Displays macOS-style HUD notifications for mode switches
struct ModeNotificationUtil {
    
    /// Shows a visual notification for mode change
    static func showModeChange(to mode: ScrollMode) {
        DispatchQueue.main.async {
            // Get mode name and icon
            let (modeName, iconName) = modeInfo(for: mode)
            
            // Create and show the HUD window
            let hud = ModeHUDWindow(mode: modeName, icon: iconName)
            hud.show()
        }
    }
    
    private static func modeInfo(for mode: ScrollMode) -> (name: String, icon: String) {
        switch mode {
        case .continuous:
            return ("Continuous Scroll", "arrow.up.arrow.down.circle.fill")
        case .autoRead:
            return ("Auto Read", "book.circle.fill")
        case .cursor:
            return ("Cursor Control", "cursorarrow.circle.fill")
        }
    }
}

// MARK: - HUD Window

private class ModeHUDWindow: NSWindow {
    
    init(mode: String, icon: String) {
        // Create window in center of main screen
        let screenFrame = NSScreen.main?.frame ?? .zero
        let hudSize = CGSize(width: 240, height: 140)
        let hudRect = NSRect(
            x: screenFrame.midX - hudSize.width / 2,
            y: screenFrame.midY - hudSize.height / 2,
            width: hudSize.width,
            height: hudSize.height
        )
        
        super.init(
            contentRect: hudRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Window configuration for HUD appearance
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .statusBar
        self.isMovable = false
        self.isReleasedWhenClosed = true
        self.ignoresMouseEvents = true
        self.hasShadow = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // Create content view
        let contentView = ModeHUDView(mode: mode, icon: icon)
        self.contentView = contentView
        
        // Fade in animation
        self.alphaValue = 0.0
        self.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.animator().alphaValue = 1.0
        })
    }
    
    func show() {
        // Auto-dismiss after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.dismiss()
        }
    }
    
    private func dismiss() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.close()
        })
    }
}

// MARK: - HUD Content View

private class ModeHUDView: NSView {
    
    private let mode: String
    private let icon: String
    
    init(mode: String, icon: String) {
        self.mode = mode
        self.icon = icon
        super.init(frame: .zero)
        self.wantsLayer = true
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupLayer() {
        guard let layer = self.layer else { return }
        
        // Frosted glass effect (like macOS HUD)
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        
        // Dark background with blur
        let blurView = NSVisualEffectView(frame: self.bounds)
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.blendingMode = .behindWindow
        blurView.autoresizingMask = [.width, .height]
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = 20
        blurView.layer?.cornerCurve = .continuous
        self.addSubview(blurView)
        
        // Stack view for icon and text
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        
        // Icon
        if let iconImage = NSImage(systemSymbolName: icon, accessibilityDescription: nil) {
            let iconView = NSImageView(image: iconImage)
            iconView.contentTintColor = .white
            iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 48, weight: .regular)
            stackView.addArrangedSubview(iconView)
        }
        
        // Mode text
        let label = NSTextField(labelWithString: mode)
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        label.alignment = .center
        stackView.addArrangedSubview(label)
        
        // Center stack view
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -20)
        ])
    }
}
