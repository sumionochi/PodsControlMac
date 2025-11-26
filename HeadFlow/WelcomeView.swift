//WelcomeView
import SwiftUI
import AppKit

struct WelcomeView: View {
    
    enum Page {
        case intro
        case permissions
    }
    
    @State private var currentPage: Page = .intro
    @ObservedObject private var permissionManager = PermissionManager.shared
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                if currentPage == .intro {
                    IntroContentView(onNext: {
                        withAnimation(.spring()) {
                            currentPage = .permissions
                        }
                    })
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    PermissionsContentView(
                        onBack: {
                            withAnimation(.spring()) {
                                currentPage = .intro
                            }
                        },
                        onFinish: {
                            finishSetup()
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .frame(
            minWidth: 600,
            idealWidth: 640,
            minHeight: 600,
            idealHeight: 680
        )
        .onReceive(timer) { _ in
            permissionManager.refreshStatus()
        }
    }
    
    func finishSetup() {
        HeadFlowSettings.hasSeenWelcome = true
        NotificationCenter.default.post(name: .headFlowSetupCompleted, object: nil)
        NSApp.keyWindow?.performClose(nil)
    }
}

// MARK: - 1. Intro View
struct IntroContentView: View {
    var onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                
                HStack(alignment: .top, spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.3),
                                        Color.accentColor.opacity(0.08)
                                    ],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: 44
                                )
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: Color.accentColor.opacity(0.15), radius: 12, x: 0, y: 4)

                        Image(systemName: "cursorarrow.motionlines")
                            .font(.system(size: 34, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Welcome to HeadFlow")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Control your Mac hands-free using head movements with your AirPods or Beats.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)

                        HStack(spacing: 10) {
                            TagCapsule(systemImage: "book", text: "Reading")
                            TagCapsule(systemImage: "chevron.left.slash.chevron.right", text: "Coding")
                            TagCapsule(systemImage: "globe", text: "Browsing")
                        }
                        .padding(.top, 4)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 4)

                Divider().padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 20) {
                    Text("What HeadFlow can do")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            title: "Head-driven scrolling",
                            text: "Tilt your head to scroll any app. Works in browsers, code editors, PDFs, and more.",
                            systemImage: "arrow.up.and.down.circle"
                        )
                        FeatureRow(
                            title: "Voice dictation mode",
                            text: "Speak naturally and see your words appear instantly in any text field.",
                            systemImage: "mic.circle"
                        )
                        FeatureRow(
                            title: "Smart auto-pause",
                            text: "Automatically pauses when you move the mouse or type on the keyboard.",
                            systemImage: "pause.circle"
                        )
                        FeatureRow(
                            title: "Global shortcuts",
                            text: "Toggle scrolling or recalibrate instantly with keyboard shortcuts.",
                            systemImage: "keyboard"
                        )
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                )
                
                Spacer(minLength: 20)
                
                HStack {
                    Spacer()
                    Button(action: onNext) {
                        HStack(spacing: 6) {
                            Text("Get Started")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(minWidth: 140)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(32)
        }
    }
}

// MARK: - 2. Permissions View (IMPROVED)
struct PermissionsContentView: View {
    @ObservedObject var pm = PermissionManager.shared
    var onBack: () -> Void
    var onFinish: () -> Void
    
    // Track which permissions have been attempted
    @State private var hasAttemptedMic = false
    @State private var hasAttemptedSpeech = false
    
    var allPermissionsGranted: Bool {
        pm.isInputMonitoringTrusted &&
        pm.motionStatus == .authorized &&
        pm.micStatus == .authorized &&
        pm.speechStatus == .authorized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            HStack(alignment: .top) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                .padding(.trailing, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Setup")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text("HeadFlow needs a few permissions to work. Click 'Allow' on each prompt—it only takes a moment!")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Progress indicator
            if !allPermissionsGranted {
                ProgressBanner(
                    granted: countGrantedPermissions(),
                    total: 4
                )
            }
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    // 1. Input Monitoring
                    PermissionRow(
                        number: 1,
                        title: "Keyboard Shortcuts",
                        description: "Lets you use keyboard shortcuts to control HeadFlow.",
                        icon: "keyboard",
                        isGranted: pm.isInputMonitoringTrusted,
                        hasAttempted: true,
                        onRequest: { pm.requestInputMonitoring() },
                        onOpenSettings: { pm.openInputMonitoringSettings() }
                    )
                    
                    // 2. Headphone Motion
                    PermissionRow(
                        number: 2,
                        title: "Head Tracking",
                        description: "Reads head movements from your AirPods or Beats headphones.",
                        icon: "airpodspro",
                        isGranted: pm.motionStatus == .authorized,
                        hasAttempted: true,
                        onRequest: { pm.requestMotion() },
                        onOpenSettings: { pm.openMotionSettings() }
                    )
                    
                    // 3. Microphone
                    PermissionRow(
                        number: 3,
                        title: "Microphone Access",
                        description: "Required for voice dictation mode to capture your speech.",
                        icon: "mic",
                        isGranted: pm.micStatus == .authorized,
                        hasAttempted: hasAttemptedMic || pm.micStatus != .notDetermined,
                        onRequest: {
                            hasAttemptedMic = true
                            pm.requestMicrophone()
                        },
                        onOpenSettings: {
                            pm.openMicrophoneSettings()
                        }
                    )
                    
                    // 4. Speech Recognition
                    PermissionRow(
                        number: 4,
                        title: "Speech Recognition",
                        description: "Converts your voice to text using Apple's speech engine.",
                        icon: "waveform",
                        isGranted: pm.speechStatus == .authorized,
                        hasAttempted: hasAttemptedSpeech || pm.speechStatus != .notDetermined,
                        onRequest: {
                            hasAttemptedSpeech = true
                            pm.requestSpeechRecognition()
                        },
                        onOpenSettings: {
                            pm.openSpeechSettings()
                        }
                    )
                }
                .padding(.vertical, 10)
            }

            Spacer()
            
            Divider()
            
            HStack {
                if !allPermissionsGranted {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text("Having trouble?")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.secondary)
                        
                        Button("Open System Settings") {
                            pm.openMicrophoneSettings()
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                }
                
                Spacer()
                
                if allPermissionsGranted {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("All Set!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button(action: onFinish) {
                    HStack(spacing: 6) {
                        Text(allPermissionsGranted ? "Start Using HeadFlow" : "Continue Anyway")
                        if allPermissionsGranted {
                            Image(systemName: "checkmark")
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 10)
        }
        .padding(32)
    }
    
    private func countGrantedPermissions() -> Int {
        var count = 0
        if pm.isInputMonitoringTrusted { count += 1 }
        if pm.motionStatus == .authorized { count += 1 }
        if pm.micStatus == .authorized { count += 1 }
        if pm.speechStatus == .authorized { count += 1 }
        return count
    }
}

// MARK: - UI Components

struct ProgressBanner: View {
    let granted: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: CGFloat(granted) / CGFloat(total))
                    .stroke(Color.accentColor, lineWidth: 3)
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: granted)
                
                Text("\(granted)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(granted) of \(total) permissions granted")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Click 'Allow' when macOS asks for permission")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.08))
        )
    }
}

struct PermissionRow: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    let isGranted: Bool
    let hasAttempted: Bool
    let onRequest: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Number badge
            ZStack {
                Circle()
                    .fill(isGranted ? Color.green : Color.accentColor)
                    .frame(width: 28, height: 28)
                
                if isGranted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isGranted ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isGranted ? Color.green : Color.secondary)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1.5)
            }
            
            Spacer()
            
            // Action button
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .padding(.top, 8)
            } else {
                Button {
                    onRequest()
                } label: {
                    Text("Allow")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(minWidth: 70)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isGranted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .opacity(isGranted ? 0.75 : 1.0)
    }
}

struct TagCapsule: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.accentColor.opacity(0.12))
        )
        .foregroundStyle(Color.accentColor)
    }
}

struct FeatureRow: View {
    let title: String
    let text: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 36, height: 36)
               
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
               
                Text(text)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
    }
}

#Preview {
    WelcomeView()
}
