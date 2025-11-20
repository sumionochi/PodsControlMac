import Foundation

/// Different ways to translate head tilt into scrolling behavior.
enum ScrollMode: Int, CaseIterable, Identifiable {
    case continuous = 0   // smooth, proportional to tilt
    case autoRead  = 2    // slow continuous scroll when tilted down (keeps old rawValue for compatibility)

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .continuous: return "Continuous"
        case .autoRead:   return "Auto-read"
        }
    }

    var shortDescription: String {
        switch self {
        case .continuous:
            return "Scroll speed scales smoothly with head tilt."
        case .autoRead:
            return "Tilt down slightly to auto-scroll for reading."
        }
    }
}
