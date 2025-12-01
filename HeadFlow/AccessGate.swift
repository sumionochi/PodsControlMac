// AccessGate.swift
import Foundation

/// Lightweight helper used from low-level code (MotionEngine, etc.)
/// to know if the user currently has access to core features.
///
/// It reads the SAME keys as PurchaseManager, so everything stays in sync,
/// but it does NOT depend on @MainActor / StoreKit.
enum AccessGate {
    private static let keyLifetimeUnlocked = "podscontrolmac.lifetimeUnlocked"
    private static let keyTrialStartDate  = "podscontrolmac.trialStartDate"
    private static let trialLengthDays: Int = 3

    /// True if the user is either:
    /// - in their 3-day trial window, or
    /// - has bought the lifetime unlock.
    static var hasFullAccess: Bool {
        let defaults = UserDefaults.standard

        // Lifetime purchase → always allowed
        if defaults.bool(forKey: keyLifetimeUnlocked) {
            return true
        }

        // No trial start stored yet → treat as “trial active”
        guard let start = defaults.object(forKey: keyTrialStartDate) as? Date else {
            return true
        }

        let end = Calendar.current.date(byAdding: .day,
                                        value: trialLengthDays,
                                        to: start) ?? start
        return Date() < end
    }
}
