//ManualScrollPauseController
import Foundation

/// Tracks recent manual (mouse/trackpad) scrolling so MotionEngine
/// can briefly pause head-based scrolling when the user scrolls by hand.
final class ManualScrollPauseController {

    static let shared = ManualScrollPauseController()
    
    private var lastManualScrollTime: CFTimeInterval = 0

    /// Current pause interval in seconds, driven by user settings.
    private var pauseInterval: CFTimeInterval {
        let seconds = HeadFlowSettings.manualScrollPauseSeconds
        // clamp to a reasonable range 0.1–1.0s
        return CFTimeInterval(max(0.1, min(1.0, seconds)))
    }

    private init() {}

    func registerManualScroll() {
        lastManualScrollTime = CFAbsoluteTimeGetCurrent()
    }

    var isPausedForManualScroll: Bool {
        // If feature is disabled in settings, never pause.
        guard HeadFlowSettings.pauseOnManualScroll else { return false }

        let now = CFAbsoluteTimeGetCurrent()
        return now - lastManualScrollTime < pauseInterval
    }
}
