// HeadFlowActions.swift
import Foundation

/// Built-in HeadFlow actions that a gesture can trigger
/// (besides generic keyboard shortcuts).
enum HeadFlowActionKind: String, Codable, CaseIterable, Identifiable, Hashable {

    // Mode / session
    case togglePerAppProfile
    case showHidePreferences
    case recalibrateNeutral
    case toggleHeadFlowScrolling

    // Tuning: increase
    case increaseAcceleration
    case increaseDamping
    case increaseDeadZone
    case increaseMaxTilt
    case increaseMaxScrollLines
    case increaseSensitivity

    // Tuning: decrease
    case decreaseAcceleration
    case decreaseDamping
    case decreaseDeadZone
    case decreaseMaxTilt
    case decreaseMaxScrollLines
    case decreaseSensitivity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .togglePerAppProfile:    return "Toggle per-app profile for current app"
        case .showHidePreferences:    return "Show Preferences"
        case .recalibrateNeutral:     return "Recalibrate neutral head position"
        case .toggleHeadFlowScrolling:return "Start / Stop HeadFlow scrolling"

        case .increaseAcceleration:   return "Increase acceleration"
        case .increaseDamping:        return "Increase damping"
        case .increaseDeadZone:       return "Increase dead zone"
        case .increaseMaxTilt:        return "Increase max tilt"
        case .increaseMaxScrollLines: return "Increase max scroll lines"
        case .increaseSensitivity:    return "Increase sensitivity"

        case .decreaseAcceleration:   return "Decrease acceleration"
        case .decreaseDamping:        return "Decrease damping"
        case .decreaseDeadZone:       return "Decrease dead zone"
        case .decreaseMaxTilt:        return "Decrease max tilt"
        case .decreaseMaxScrollLines: return "Decrease max scroll lines"
        case .decreaseSensitivity:    return "Decrease sensitivity"
        }
    }
}
