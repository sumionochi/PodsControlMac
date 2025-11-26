//MotionLiveState
import Foundation

/// Shared live state for the "Live response" panel.
/// Updated by MotionEngine, observed by PreferencesView.
@available(macOS 14.0, *)
final class MotionLiveState: ObservableObject {

    static let shared = MotionLiveState()

    enum Status {
        case idle          // scrolling disabled / no motion yet
        case tracking      // receiving motion + scrolling enabled
        case disconnected  // no supported headphones connected
        case needsSetup    // missing Accessibility or Motion permission
        case pausedPointer
        case pausedTyping
        case pausedModifier
        case pausedManualScroll  // paused due to manual scroll detection
        case pausedDictation
    }

    /// Current tilt relative to neutral, in degrees (clamped to ±maxTilt).
    @Published var tiltDegrees: Double = 0

    /// Tilt as a percentage of max tilt (−100...+100).
    @Published var tiltPercent: Double = 0

    /// Current scroll velocity in lines per second (signed: +up, −down).
    @Published var velocityLinesPerSecond: Double = 0

    /// Current scroll mode (continuous / auto-read).
    @Published var mode: ScrollMode = .continuous

    /// Overall live status for the UI.
    @Published var status: Status = .idle
}
