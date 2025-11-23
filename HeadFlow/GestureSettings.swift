// GestureSettings.swift
import Foundation

/// What a gesture does.
enum GestureAction: Codable, Equatable, Hashable {
    case none
    case headFlow(HeadFlowActionKind)
    case standardShortcut(StandardShortcutKind)
    case customShortcut(UUID) // refers to CustomShortcut.id

    // Coding for enum-with-associated-values
    private enum CodingKeys: String, CodingKey {
        case kind
        case headFlow
        case standard
        case customID
    }

    private enum Kind: String, Codable {
        case none
        case headFlow
        case standardShortcut
        case customShortcut
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .none:
            self = .none
        case .headFlow:
            let value = try container.decode(HeadFlowActionKind.self, forKey: .headFlow)
            self = .headFlow(value)
        case .standardShortcut:
            let value = try container.decode(StandardShortcutKind.self, forKey: .standard)
            self = .standardShortcut(value)
        case .customShortcut:
            let id = try container.decode(UUID.self, forKey: .customID)
            self = .customShortcut(id)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .none:
            try container.encode(Kind.none, forKey: .kind)
        case .headFlow(let value):
            try container.encode(Kind.headFlow, forKey: .kind)
            try container.encode(value, forKey: .headFlow)
        case .standardShortcut(let value):
            try container.encode(Kind.standardShortcut, forKey: .kind)
            try container.encode(value, forKey: .standard)
        case .customShortcut(let id):
            try container.encode(Kind.customShortcut, forKey: .kind)
            try container.encode(id, forKey: .customID)
        }
    }
}

/// Mapping: in a given context (HeadFlow on/off), when gesture X fires, run Action Y.
struct GestureMapping: Codable, Equatable {
    var context: GestureContext
    var gesture: GestureType
    var action: GestureAction
}

/// Complete persisted settings for gestures.
struct GestureSettings: Codable, Equatable {
    /// All mappings (per context + gesture).
    var mappings: [GestureMapping]

    /// User-defined custom shortcuts bank.
    var customShortcuts: [CustomShortcut]

    static func empty() -> GestureSettings {
        GestureSettings(mappings: [], customShortcuts: [])
    }
}
