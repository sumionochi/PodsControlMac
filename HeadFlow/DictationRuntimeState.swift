// DictationRuntimeState.swift
import Foundation

/// Lightweight bridge so non-@MainActor code (like MotionEngine) can
/// see whether dictation is active.
final class DictationRuntimeState {
    static let shared = DictationRuntimeState()
    private init() {}

    /// True while DictationController is actively listening.
    var isDictating: Bool = false
}
