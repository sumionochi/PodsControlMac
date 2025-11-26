//  PermissionManager.swift

import Foundation
import CoreMotion
import ApplicationServices
import AppKit
import AVFoundation
import Speech

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var isAccessibilityTrusted: Bool = AXIsProcessTrusted()
    @Published var isInputMonitoringTrusted: Bool = false
    @Published var motionStatus: CMAuthorizationStatus = .notDetermined
    
    @Published var micStatus: AVAuthorizationStatus = .notDetermined
    @Published var speechStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private let motionManager = CMHeadphoneMotionManager()
    
    init() {
        if #available(macOS 14.0, *) {
            self.motionStatus = CMHeadphoneMotionManager.authorizationStatus()
        }
        
        self.micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        self.speechStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    func refreshStatus() {
        DispatchQueue.main.async {
            self.isAccessibilityTrusted = AXIsProcessTrusted()
            
            if #available(macOS 14.0, *) {
                self.motionStatus = CMHeadphoneMotionManager.authorizationStatus()
            }
            
            self.micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
            self.speechStatus = SFSpeechRecognizer.authorizationStatus()
        }
    }
    
    // MARK: - Accessibility
    
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Input Monitoring
    
    func requestInputMonitoring() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) else {
            return
        }
        
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
    
    // MARK: - Motion
    
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
    
    // MARK: - Microphone (Apple's Recommended Method)
    
    func requestMicrophone() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        print("Current mic status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .notDetermined:
            // First time - request permission
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    print("Microphone permission: \(granted ? "GRANTED" : "DENIED")")
                    self?.micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                }
            }
            
        case .restricted, .denied:
            // Already denied - open settings
            print("Opening microphone settings (already denied)")
            openMicrophoneSettings()
            
        case .authorized:
            // Already granted
            print("Microphone already authorized")
            
        @unknown default:
            openMicrophoneSettings()
        }
    }
    
    func openMicrophoneSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - Speech Recognition (Apple's Recommended Method)
    
    func requestSpeechRecognition() {
        let currentStatus = SFSpeechRecognizer.authorizationStatus()
        
        print("Current speech status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .notDetermined:
            // First time - request permission
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    print("Speech recognition permission: \(status.rawValue)")
                    self?.speechStatus = status
                }
            }
            
        case .restricted, .denied:
            // Already denied - open settings
            print("Opening speech settings (already denied)")
            openSpeechSettings()
            
        case .authorized:
            // Already granted
            print("Speech recognition already authorized")
            
        @unknown default:
            openSpeechSettings()
        }
    }
    
    func openSpeechSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")!
        NSWorkspace.shared.open(url)
    }
}
