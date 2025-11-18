import Foundation

/// Different ways to translate head tilt into scrolling behavior.
enum ScrollMode: Int, CaseIterable, Identifiable {
    case continuous = 0   // smooth, proportional to tilt
    case step            // chunked "page-like" steps
    case autoRead        // slow continuous scroll when tilted down

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .continuous: return "Continuous"
        case .step:       return "Step"
        case .autoRead:   return "Auto-read"
        }
    }

    var shortDescription: String {
        switch self {
        case .continuous:
            return "Scroll speed scales smoothly with head tilt."
        case .step:
            return "Each strong tilt triggers a bigger scroll step."
        case .autoRead:
            return "Tilt down slightly to auto-scroll for reading."
        }
    }
}
