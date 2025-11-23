import SwiftUI
import AppKit

struct WelcomeView: View {
    
    enum Page {
        case intro
        case permissions
    }
    
    @State private var currentPage: Page = .intro
    // Assuming PermissionManager is available from the previous file
    @ObservedObject private var permissionManager = PermissionManager.shared
    
    // Timer to poll for permission changes if user changes them in System Settings
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Elegant gradient background
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
        // 1. Mark as seen
        HeadFlowSettings.hasSeenWelcome = true
        // 2. Notify AppDelegate to start services
        NotificationCenter.default.post(name: .headFlowSetupCompleted, object: nil)
        // 3. Close window
        NSApp.keyWindow?.performClose(nil)
    }
}

// MARK: - 1. Intro View
struct IntroContentView: View {
    var onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                
                // --- Header + Hero Icon ---
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

                        Text("Hands-free scrolling for reading, coding, and browsing with your AirPods or Beats.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)

                        // Use case chips
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

                // --- Features Section ---
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
                            title: "Per-app profiles",
                            text: "Make Safari slow and relaxed, Xcode faster, and Notion ultra-precise.",
                            systemImage: "square.grid.2x2"
                        )
                        FeatureRow(
                            title: "Smart pause & safety",
                            text: "Pauses automatically when you move the mouse or type.",
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
                
                // --- Next Button ---
                HStack {
                    Spacer()
                    Button(action: onNext) {
                        Text("Next: Setup Permissions")
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

// MARK: - 2. Permissions View
struct PermissionsContentView: View {
    @ObservedObject var pm = PermissionManager.shared
    var onBack: () -> Void
    var onFinish: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // Header with Back Button
            HStack(alignment: .top) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .contentShape(Rectangle()) // Increases hit area
                }
                .buttonStyle(.plain) // Removes standard button background
                .padding(.top, 6)
                .padding(.trailing, 8)
                // Add hover effect or color if desired
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grant Permissions")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text("To function correctly, HeadFlow needs access to Input Monitoring (to detect keyboard shortcuts) and Motion data (from your headphones).")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    // 1. Input Monitoring Permission (changed from Accessibility)
                    PermissionRow(
                        title: "Input Monitoring",
                        description: "Required to detect keyboard shortcuts and control scrolling.",
                        icon: "keyboard",
                        isGranted: pm.isInputMonitoringTrusted,
                        onRequest: { pm.requestInputMonitoring() },
                        onOpenSettings: { pm.openInputMonitoringSettings() }
                    )
                    
                    // 2. Motion Permission
                    PermissionRow(
                        title: "Headphone Motion",
                        description: "Required to read head tracking data from AirPods/Beats.",
                        icon: "airpodspro",
                        isGranted: pm.motionStatus == .authorized,
                        onRequest: { pm.requestMotion() },
                        onOpenSettings: { pm.openMotionSettings() }
                    )
                }
                .padding(.vertical, 10)
            }

            Spacer()
            
            Divider()
            
            // Footer Action
            HStack {
                // Troubleshooting link
                Button("Troubleshooting…") {
                    pm.openInputMonitoringSettings()
                }
                .buttonStyle(.link)
                .font(.footnote)
                
                Spacer()
                
                Button(action: onFinish) {
                    Text("Start HeadFlow")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 10)
        }
        .padding(32)
    }
}

// MARK: - UI Components

struct PermissionRow: View {
    let title: String
    let description: String
    let icon: String
    let isGranted: Bool
    let onRequest: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
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
            
            // Status / Actions
            if isGranted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Allowed")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.green)
                .padding(.top, 8)
            } else {
                VStack(alignment: .trailing, spacing: 6) {
                    Button("Allow") {
                        onRequest()
                    }
                    .controlSize(.regular)
                    
                    Button("Open Settings") {
                        onOpenSettings()
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                    .foregroundStyle(Color.accentColor)
                }
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
                .stroke(isGranted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .opacity(isGranted ? 0.8 : 1.0) // Fade out slightly if granted
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
