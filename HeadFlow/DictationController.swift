// DictationController.swift
import Foundation
import SwiftUI
import AppKit
import Speech
import AVFoundation

/// Controls the dictation HUD + start/stop of dictation,
/// and inserts recognized text into the focused text field.
@MainActor
final class DictationController: NSObject, ObservableObject {

    static let shared = DictationController()

    // MARK: - Published UI state (for HUD)

    /// Whether the floating HUD window is visible.
    @Published var isHUDVisible: Bool = false

    /// Whether we're actively recording + recognizing.
    @Published var isListening: Bool = false

    /// True while we're waiting for the system's Speech permission dialog.
    @Published var isRequestingPermission: Bool = false

    /// True if user denied / restricted speech recognition.
    @Published var permissionDenied: Bool = false

    /// Live partial text from the recognizer (for grey preview in HUD).
    @Published var partialText: String = ""

    /// Last fully committed phrase (for small confirmation in HUD).
    @Published var lastCommittedText: String = ""

    /// Human-readable error text for the HUD.
    @Published var errorMessage: String?

    // MARK: - Window
    
    private var hudWindow: NSPanel?

    // MARK: - Speech engine internals

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.current)

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    /// Track the last good (non-empty) transcription
    private var lastGoodTranscription: String = ""
    private var hasCommittedThisSession: Bool = false

    /// Used to detect “no new result arrived” when the silence timer fires.
    private var recognitionSequence: Int = 0
    /// User-configurable delay before auto-commit kicks in.
    /// (Make sure HeadFlowSettings exposes this; we clamp to 0.5–10s.)
    private var autoCommitDelay: TimeInterval {
        let raw = HeadFlowSettings.dictationAutoCommitDelaySeconds
        return min(max(raw, 0.5), 10.0)
    }
    
    // MARK: - Auto-commit state
   /// Increments every time we schedule an auto-commit, so only the latest fires.
   private var autoCommitSequence: Int = 0
   /// Handle to the currently scheduled auto-commit work item (if any).
   private var autoCommitWorkItem: DispatchWorkItem?

    private override init() {
        super.init()
    }

    // MARK: - HUD control

    func toggleHUD() {
        if isHUDVisible {
            hideHUD()
        } else {
            showHUD()
        }
    }

    @MainActor
    func showHUD() {
        if let panel = hudWindow {
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.level = .statusBar
            panel.orderFrontRegardless()
            isHUDVisible = true
            return
        }

        let rootView = DictationHUDView(controller: self)
        let hostingView = NSHostingView(rootView: rootView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 80),
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.hasShadow = true

        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isOpaque = false
        panel.backgroundColor = .clear

        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        panel.isMovableByWindowBackground = true
        panel.contentView = hostingView

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let origin = NSPoint(
                x: screenFrame.midX - panel.frame.width / 2,
                y: screenFrame.midY - panel.frame.height / 2
            )
            panel.setFrameOrigin(origin)
        } else {
            panel.center()
        }

        panel.orderFrontRegardless()

        self.hudWindow = panel
        self.isHUDVisible = true
    }

    func hideHUD() {
        hudWindow?.orderOut(nil)
        isHUDVisible = false

        if isListening {
            stopDictation()
        }
    }

    // MARK: - Mic / dictation control

    func toggleMic() {
        if isListening {
            // Manual stop: commit whatever we have right now, then stop.
            commitCurrentText()
        } else {
            startDictation()
        }
    }

    func startDictation() {
        guard HeadFlowSettings.dictationEnabled else {
            print("DictationController: dictation feature is disabled in settings")
            errorMessage = "Dictation is disabled in HeadFlow Preferences."
            return
        }

        errorMessage = nil
        permissionDenied = false

        guard let recognizer = speechRecognizer else {
            errorMessage = "Could not create a speech recognizer for your language."
            print("DictationController: SFSpeechRecognizer is nil")
            return
        }

        guard recognizer.isAvailable else {
            errorMessage = "Speech recognition is not available right now."
            print("DictationController: recognizer is not available")
            return
        }

        checkMicrophoneAndStart(recognizer: recognizer)
    }

    private func checkMicrophoneAndStart(recognizer: SFSpeechRecognizer) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            checkSpeechPermissionAndStart(recognizer: recognizer)

        case .notDetermined:
            isRequestingPermission = true
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.isRequestingPermission = false

                    if granted {
                        self.checkSpeechPermissionAndStart(recognizer: recognizer)
                    } else {
                        self.permissionDenied = true
                        self.errorMessage = "HeadFlow doesn't have permission to use your microphone."
                        print("DictationController: microphone permission denied")
                    }
                }
            }

        case .denied, .restricted:
            permissionDenied = true
            errorMessage = "HeadFlow doesn't have permission to use your microphone.\nEnable it in System Settings → Privacy & Security → Microphone."
            print("DictationController: microphone permission denied/restricted")

        @unknown default:
            errorMessage = "Unknown microphone permission state."
        }
    }

    private func checkSpeechPermissionAndStart(recognizer: SFSpeechRecognizer) {
        let authStatus = SFSpeechRecognizer.authorizationStatus()

        switch authStatus {
        case .authorized:
            internalStartDictation(with: recognizer)

        case .notDetermined:
            isRequestingPermission = true
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                guard let self = self else { return }
                Task { @MainActor in
                    self.isRequestingPermission = false
                    switch status {
                    case .authorized:
                        self.internalStartDictation(with: recognizer)

                    case .denied, .restricted:
                        self.permissionDenied = true
                        self.errorMessage = "Enable 'Speech Recognition' for HeadFlow in System Settings → Privacy & Security."
                        print("DictationController: speech permission denied/restricted")

                    case .notDetermined:
                        break

                    @unknown default:
                        break
                    }
                }
            }

        case .denied, .restricted:
            permissionDenied = true
            errorMessage = "HeadFlow doesn't have permission to use speech recognition."
            print("DictationController: speech permission denied/restricted")

        @unknown default:
            break
        }
    }

    /// Real speech-recognition startup once we have permission
    private func internalStartDictation(with recognizer: SFSpeechRecognizer) {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        lastGoodTranscription = ""
        recognitionSequence = 0
        autoCommitWorkItem?.cancel()
        autoCommitWorkItem = nil
        hasCommittedThisSession = false
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = false
            print("DictationController: On-device recognition is available")
        }
        
        request.taskHint = .dictation
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        print("DictationController: Audio format: \(recordingFormat)")
        print("DictationController: Sample rate: \(recordingFormat.sampleRate)")

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("DictationController: ✅ Audio engine started successfully")
        } catch {
            errorMessage = "Could not start audio engine: \(error.localizedDescription)"
            print("DictationController: ❌ audioEngine.start() error: \(error)")
            inputNode.removeTap(onBus: 0)
            return
        }

        isListening = true
        DictationRuntimeState.shared.isDictating = true
        partialText = ""
        lastCommittedText = ""

        print("DictationController: Starting recognition task with locale: \(recognizer.locale.identifier)")

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            print("DictationController: 📞 Recognition callback received")
            
            if let result = result {
                print("DictationController: 📝 Got result - isFinal: \(result.isFinal)")
                print("DictationController: 📝 Text: '\(result.bestTranscription.formattedString)'")
            }
            
            if let error = error {
                print("DictationController: ❌ Got error: \(error.localizedDescription)")
            }
            
            Task { @MainActor in
                self.handleRecognitionCallback(result: result, error: error)
            }
        }
        
        if recognitionTask == nil {
            print("DictationController: ❌ Failed to create recognition task!")
            errorMessage = "Failed to start speech recognition"
            stopDictation()
        } else {
            print("DictationController: ✅ Recognition task created successfully")
        }
    }
    
    // MARK: - Auto-commit helper

    private func scheduleAutoCommitIfNeeded(_ latestText: String) {
        // Don’t schedule if there’s no text
        let trimmed = latestText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Cancel any previous pending auto-commit
        autoCommitWorkItem?.cancel()

        // Bump sequence so older work items know they’re stale
        autoCommitSequence &+= 1
        let currentSeq = autoCommitSequence

        let delay = autoCommitDelay   // 🔹 use clamped value
        print("DictationController: Scheduling auto-commit in \(delay)s (seq \(currentSeq))")

        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                // Only the most recent scheduled task may auto-commit
                guard currentSeq == self.autoCommitSequence else {
                    print("DictationController: Auto-commit (seq \(currentSeq)) cancelled by newer sequence")
                    return
                }

                print("DictationController: ⏱ Auto-committing after \(delay)s of silence")
                self.commitCurrentText()
            }
        }

        autoCommitWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    /// Handle result/error from SFSpeechRecognizer on the main actor
    private func handleRecognitionCallback(
        result: SFSpeechRecognitionResult?,
        error: Error?
    ) {
        if let result = result {
            let text = result.bestTranscription.formattedString
            print("DictationController: Updating partial text: '\(text)'")
            
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lastGoodTranscription = text
                print("DictationController: Saved as last good transcription")
            }
            
            updatePartialTranscription(text)

            if result.isFinal {
                print("DictationController: ✅ Final result received!")
                
                // If we've already auto-committed / manually committed, just stop.
                if hasCommittedThisSession {
                    print("DictationController: Final result arrived but text was already committed, stopping without inserting again.")
                    stopDictation()
                    return
                }

                let finalText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? text
                    : lastGoodTranscription
                
                print("DictationController: Using final text: '\(finalText)'")
                
                if !finalText.isEmpty {
                    handleFinalTranscription(finalText)
                } else {
                    print("DictationController: ⚠️ No text to insert (both final and last good are empty)")
                }
                
                stopDictation()
                return
            } else {
                scheduleAutoCommitIfNeeded(text)
            }
        }

        if let nsError = error as NSError? {
            print("DictationController: ❌ Recognition error:")
            print("  - Description: \(nsError.localizedDescription)")
            print("  - Domain: \(nsError.domain)")
            print("  - Code: \(nsError.code)")

            // No speech detected
            if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 1110 {
                print("DictationController: No speech detected, stopping gracefully")
                stopDictation()
                return
            }
            
            // Recognition was cancelled/interrupted
            if (nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 203) ||
               (nsError.domain == "kLSRErrorDomain" && nsError.code == 301) {

                print("DictationController: Recognition was cancelled")

                // Only commit on cancel if we *haven't* already committed
                if !hasCommittedThisSession, !lastGoodTranscription.isEmpty {
                    print("DictationController: Using last good transcription before cancellation")
                    handleFinalTranscription(lastGoodTranscription)
                }
                
                stopDictation()
                return
            }

            errorMessage = nsError.localizedDescription
            stopDictation()
        }
    }

    /// Schedule / reset the silence timer for auto-commit
    private func scheduleAutoCommit() {
        autoCommitSequence &+= 1
        let current = autoCommitSequence
        let delay = HeadFlowSettings.dictationAutoCommitDelaySeconds

        print("DictationController: Scheduling auto-commit in \(delay)s (seq \(current))")

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            guard self.autoCommitSequence == current else {
                // New speech arrived, older timer is obsolete
                return
            }
            guard self.isListening else { return }

            print("DictationController: ⏱ Auto-committing after \(delay)s of silence")

            let finalText = self.partialText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !finalText.isEmpty {
                self.handleFinalTranscription(finalText)
            } else if !self.lastGoodTranscription.isEmpty {
                self.handleFinalTranscription(self.lastGoodTranscription)
            }
            self.stopDictation()
        }
    }

    /// Called when the silence timer fires; only commits if no newer result arrived.
    private func autoCommitIfStillIdle(sequence: Int) {
        guard isListening else {
            print("DictationController: auto-commit skipped (not listening)")
            return
        }
        guard sequence == recognitionSequence else {
            print("DictationController: auto-commit skipped (newer result arrived)")
            return
        }

        let primary = partialText.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = lastGoodTranscription.trimmingCharacters(in: .whitespacesAndNewlines)

        let textToCommit = !primary.isEmpty ? primary : fallback

        guard !textToCommit.isEmpty else {
            print("DictationController: auto-commit timer fired but no text to commit")
            return
        }

        print("DictationController: ⏱ Auto-committing after \(autoCommitDelay)s of silence")
        handleFinalTranscription(textToCommit)
        stopDictation()
    }

    func stopDictation() {
        autoCommitWorkItem?.cancel()
        autoCommitWorkItem = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isListening = false
        isRequestingPermission = false
        DictationRuntimeState.shared.isDictating = false
        lastGoodTranscription = ""

        // Reset HUD text so it looks “ready” again
        partialText = ""
        lastCommittedText = ""
    }
    
    /// Manually commit the current partial text and stop dictation (mic button)
    func commitCurrentText() {
        guard isListening else { return }
        
        let primary = partialText.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = lastGoodTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
        let textToCommit = !primary.isEmpty ? primary : fallback
        
        if !textToCommit.isEmpty {
            print("DictationController: Manually committing: '\(textToCommit)'")
            handleFinalTranscription(textToCommit)
        } else {
            print("DictationController: No text to commit")
        }
        
        stopDictation()
    }

    // MARK: - Transcription helpers

    /// For live partial updates from the speech recognizer
    func updatePartialTranscription(_ text: String) {
        partialText = text
    }

    /// Called when the speech recognizer produces a final, stable chunk of text
    func handleFinalTranscription(_ rawText: String) {
        print("DictationController: Processing final transcription: '\(rawText)'")
        
        let processed = DictationTextProcessor.process(rawText)
        guard !processed.isEmpty else {
            print("DictationController: ⚠️ Processed text is empty")
            return
        }
        
        // If we've already committed this session, don't insert again
        if hasCommittedThisSession {
            print("DictationController: ⚠️ Already committed this session, skipping duplicate insert")
            return
        }
        
        hasCommittedThisSession = true   // ⬅️ mark session as committed
        
        print("DictationController: Processed text: '\(processed)'")
        print("DictationController: Attempting to insert text...")
        
        insertTextIntoFocusedField(processed)
        commit(text: processed)
        
        print("DictationController: ✅ Text committed successfully")
    }

    /// For manual commits (if we want to show what just got inserted)
    func commit(text: String) {
        lastCommittedText = text
        partialText = ""
    }

    // MARK: - Insertion into focused field

    /// Sends the given text into whatever currently has keyboard focus,
    /// using CGEvents / clipboard so it works across apps.
    private func insertTextIntoFocusedField(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("DictationController: ⚠️ Cannot insert empty text")
            return
        }

        print("DictationController: Inserting text via TextInjectionEngine: '\(trimmed)'")
        print("DictationController: Text length: \(trimmed.count) characters")

        // We still need Accessibility permission for CGEvents.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let hasAccess = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !hasAccess {
            print("DictationController: ❌ Missing Accessibility permission!")
            errorMessage = """
            HeadFlow needs Accessibility permission to type for you.
            System Settings → Privacy & Security → Accessibility → enable “HeadFlow”.
            """
            return
        }

        print("DictationController: ✅ Has Accessibility permission, typing now…")
        TextInjectionEngine.typeText(trimmed)
    }

}
