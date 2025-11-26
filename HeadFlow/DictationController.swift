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
            errorMessage = "Dictation is disabled in HeadFlow Preferences."
            return
        }

        errorMessage = nil
        permissionDenied = false

        guard let recognizer = speechRecognizer else {
            errorMessage = "Could not create a speech recognizer for your language."
            return
        }

        guard recognizer.isAvailable else {
            errorMessage = "Speech recognition is not available right now."
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
                    }
                }
            }

        case .denied, .restricted:
            permissionDenied = true
            errorMessage = "HeadFlow doesn't have permission to use your microphone.\nEnable it in System Settings → Privacy & Security → Microphone."

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
        autoCommitWorkItem?.cancel()
        autoCommitWorkItem = nil
        hasCommittedThisSession = false
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = false
        }
        
        request.taskHint = .dictation
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Could not start audio engine: \(error.localizedDescription)"
            inputNode.removeTap(onBus: 0)
            return
        }

        isListening = true
        DictationRuntimeState.shared.isDictating = true
        partialText = ""
        lastCommittedText = ""

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleRecognitionCallback(result: result, error: error)
            }
        }
        
        if recognitionTask == nil {
            errorMessage = "Failed to start speech recognition"
            stopDictation()
        } else {
            print("DictationController: ✅ Recognition task created successfully")
        }
    }
    
    // MARK: - Auto-commit helper

    private func scheduleAutoCommitIfNeeded(_ latestText: String) {
        // NEW: Check if auto-commit is enabled
        guard HeadFlowSettings.dictationAutoCommitEnabled else {
            return
        }
        // Don’t schedule if there’s no text
        let trimmed = latestText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Cancel any previous pending auto-commit
        autoCommitWorkItem?.cancel()

        // Bump sequence so older work items know they’re stale
        autoCommitSequence &+= 1
        let currentSeq = autoCommitSequence

        let delay = autoCommitDelay   // 🔹 use clamped value

        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                // Only the most recent scheduled task may auto-commit
                guard currentSeq == self.autoCommitSequence else {
                    return
                }

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
            let rawText = result.bestTranscription.formattedString
            
            if !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lastGoodTranscription = rawText
            }
            
            // PREVIEW shown in HUD = processed text
            let preview = DictationTextProcessor.process(rawText)
            updatePartialTranscription(preview)

            scheduleAutoCommitIfNeeded(rawText)
            
            if result.isFinal {
                
                if hasCommittedThisSession {
                    stopDictation()
                    return
                }

                // Use RAW text for final processing
                let finalRaw = !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? rawText
                    : lastGoodTranscription
                                
                if !finalRaw.isEmpty {
                    handleFinalTranscription(finalRaw)
                } else {
                }
                
                stopDictation()
                return
            }
        }


        if let nsError = error as NSError? {
            // No speech detected
            if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 1110 {
                stopDictation()
                return
            }
            
            // Recognition was cancelled/interrupted
            if (nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 203) ||
               (nsError.domain == "kLSRErrorDomain" && nsError.code == 301) {

                // Only commit on cancel if we *haven't* already committed
                if !hasCommittedThisSession, !lastGoodTranscription.isEmpty {
                    handleFinalTranscription(lastGoodTranscription)
                }
                
                stopDictation()
                return
            }

            errorMessage = nsError.localizedDescription
            stopDictation()
        }
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
    /// Manually commit the current text and stop dictation (mic button)
    func commitCurrentText() {
        guard isListening else { return }
        
        // Always commit RAW text, not the HUD preview
        let raw = lastGoodTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !raw.isEmpty {
            handleFinalTranscription(raw)
        } else {
            print("DictationController: No RAW text to commit")
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
        let processed = DictationTextProcessor.process(rawText)
        guard !processed.isEmpty else {
            return
        }
        
        hasCommittedThisSession = true
        
        insertTextIntoFocusedField(processed)
        commit(text: processed)
        
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
            return
        }

        // We still need Accessibility permission for CGEvents.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let hasAccess = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !hasAccess {
            errorMessage = """
            HeadFlow needs Accessibility permission to type for you.
            System Settings → Privacy & Security → Accessibility → enable “HeadFlow”.
            """
            return
        }

        TextInjectionEngine.typeText(trimmed)
    }

}
