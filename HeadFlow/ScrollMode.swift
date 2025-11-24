import Foundation

/// Different ways to translate head tilt into scrolling behavior.
enum ScrollMode: Int, CaseIterable, Identifiable {
    case continuous = 0   // smooth, proportional to tilt
    case autoRead   = 2   // slow continuous scroll when tilted down
    case cursor     = 3   // head movements control mouse cursor

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .continuous: return "Continuous"
        case .autoRead:   return "Auto-read"
        case .cursor:     return "Cursor"
        }
    }

    var shortDescription: String {
        switch self {
        case .continuous:
            return "Scroll speed scales smoothly with head tilt."
        case .autoRead:
            return "Tilt down slightly to auto-scroll for reading."
        case .cursor:
            return "Control mouse pointer with head movements."
        }
    }
}
