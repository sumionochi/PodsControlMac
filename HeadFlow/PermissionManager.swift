//  PermissionManager.swift

import Foundation
import CoreMotion
import ApplicationServices
import AppKit

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var isAccessibilityTrusted: Bool = AXIsProcessTrusted()
    // Default to true or false based on your preference, but we won't aggressively check it anymore
    @Published var isInputMonitoringTrusted: Bool = false
    @Published var motionStatus: CMAuthorizationStatus = .notDetermined
    
    private let motionManager = CMHeadphoneMotionManager()
    
    init() {
        // FIX: Do NOT check Input Monitoring here. It triggers the popup immediately.
        // checkInputMonitoring()
        
        if #available(macOS 14.0, *) {
            self.motionStatus = CMHeadphoneMotionManager.authorizationStatus()
        }
    }
    
    func refreshStatus() {
        self.isAccessibilityTrusted = AXIsProcessTrusted()
        // We skip checking input monitoring to avoid popups
        
        if #available(macOS 14.0, *) {
            self.motionStatus = CMHeadphoneMotionManager.authorizationStatus()
        }
    }
    
    // MARK: - Requests
    
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // FIX: This function was causing the keyboard block.
    // Even if we don't use it in the UI anymore, it must be safe if called.
    func requestInputMonitoring() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                // CRITICAL FIX: You MUST return the event.
                // Returning nil blocks the keyboard globally.
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) else {
            return
        }
        
        // If we successfully created it, we are trusted.
        // We immediately invalidate it so we don't keep a tap running needlessly.
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CFMachPortInvalidate(eventTap)
        
        self.isInputMonitoringTrusted = true
    }

    func openInputMonitoringSettings() {
         if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func requestMotion() {
        if #available(macOS 14.0, *) {
            guard motionManager.isDeviceMotionAvailable else { return }
            motionManager.startDeviceMotionUpdates()
            motionManager.stopDeviceMotionUpdates()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.motionStatus = CMHeadphoneMotionManager.authorizationStatus()
            }
        }
    }
    
    func openMotionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
    }
}
