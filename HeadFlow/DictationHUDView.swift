import SwiftUI

struct DictationHUDView: View {
    @ObservedObject var controller: DictationController

    // MARK: - Derived UI state

    private var canToggleMic: Bool {
        HeadFlowSettings.dictationEnabled &&
        !controller.isRequestingPermission &&
        !controller.permissionDenied
    }

    private var statusTitle: String {
        if !HeadFlowSettings.dictationEnabled {
            return "Dictation disabled"
        }
        if controller.permissionDenied {
            return "Permission required"
        }
        if controller.isRequestingPermission {
            return "Requesting permission…"
        }
        return controller.isListening ? "Listening…" : "Dictation ready"
    }

    private var statusSubtitle: String {
        if !HeadFlowSettings.dictationEnabled {
            return "Turn on Dictation in HeadFlow Preferences to use this feature."
        }
        if let error = controller.errorMessage, !error.isEmpty {
            return error
        }
        if controller.permissionDenied {
            return "Allow Speech Recognition in System Settings → Privacy & Security."
        }
        if controller.isRequestingPermission {
            return "Please approve the speech recognition prompt."
        }

        // Normal live text / hints
        if !controller.partialText.isEmpty {
            return controller.partialText
        } else if !controller.lastCommittedText.isEmpty {
            return controller.lastCommittedText
        } else {
            return "Place the text cursor in any field, then press the mic shortcut."
        }
    }

    private var statusColor: Color {
        if !HeadFlowSettings.dictationEnabled { return .gray }
        if controller.permissionDenied { return .red }
        if controller.isRequestingPermission { return .yellow }
        if controller.isListening { return .red }
        return .secondary
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(radius: 8)

            HStack(spacing: 10) {
                // Status dot
                Circle()
                    .fill(statusColor.opacity(controller.isListening ? 1.0 : 0.7))
                    .frame(width: 8, height: 8)
                    .shadow(color: .red.opacity(controller.isListening ? 0.7 : 0.0),
                            radius: 5)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(statusTitle)
                            .font(.system(size: 12, weight: .semibold))

                        if controller.isRequestingPermission {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }

                    Text(statusSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(
                            (controller.errorMessage != nil || controller.permissionDenied)
                            ? AnyShapeStyle(Color.red.opacity(0.9))
                            : controller.partialText.isEmpty && controller.lastCommittedText.isEmpty
                                ? AnyShapeStyle(.tertiary)  // ✅ Fixed: Uses hierarchical style
                                : AnyShapeStyle(.secondary) // ✅ Fixed: Wrapped for type consistency
                        )
                        .lineLimit(2)
                }

                Spacer()

                // Mic button
                Button(action: {
                    controller.toggleMic()
                }) {
                    Image(systemName: controller.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            canToggleMic
                            ? (controller.isListening ? Color.red : Color.primary)
                            : Color.secondary
                        )
                }
                .buttonStyle(.borderless)
                .help(
                    !HeadFlowSettings.dictationEnabled
                    ? "Enable dictation in HeadFlow Preferences to use the mic."
                    : (controller.isListening ? "Stop dictation" : "Start dictation")
                )
                .disabled(!canToggleMic)

                // Close HUD
                Button(action: {
                    controller.hideHUD()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help("Hide dictation HUD")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .padding(6) // small inset to avoid hard edges
    }
}

#Preview {
    DictationHUDView(controller: DictationController.shared)
        .frame(width: 360, height: 80)
}
