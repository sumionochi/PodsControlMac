// GestureTypes.swift
import Foundation

/// High-level gesture types HeadFlow can detect.
enum GestureType: String, Codable, CaseIterable, Identifiable {
    case tiltLeft
    case tiltRight
    case nodDown
    case nodUp
    case shake

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tiltLeft:  return "Tilt / look left"
        case .tiltRight: return "Tilt / look right"
        case .nodDown:   return "Nod down"
        case .nodUp:     return "Nod up"
        case .shake:     return "Shake left ↔ right"
        }
    }
}

/// Whether HeadFlow scrolling is currently on or off.
/// We use this to decide which gestures are valid.
enum GestureContext: String, Codable {
    case headFlowOn
    case headFlowOff
}
