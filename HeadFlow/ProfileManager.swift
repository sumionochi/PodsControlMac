import Foundation
import AppKit

/// Per-app configuration for HeadFlow.
struct AppProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var bundleIdentifier: String
    var appName: String

    /// Whether HeadFlow is allowed in this app at all.
    var isEnabled: Bool

    /// Per-app overrides. Start with the main knobs:
    /// 0–100, same scale as global sensitivity.
    var scrollSensitivity: Double

    /// 1–500 lines per update.
    var baseLines: Double

    /// Per-app advanced tuning (initially copied from global).
    var deadZoneDegrees: Double
    var maxTiltDegrees: Double

    /// ScrollMode raw value (Int).
    var scrollModeRaw: Int
}

/// Fully resolved config for a given app (global + per-app override merged).
struct HeadFlowEffectiveConfig {
    var isEnabled: Bool
    var scrollSensitivity: Double
    var baseLines: Int32
    var deadZoneDegrees: Double
    var maxTiltDegrees: Double
    var scrollMode: ScrollMode
}

/// Manages per-app profiles and persists them in UserDefaults.
final class ProfileManager: ObservableObject {

    static let shared = ProfileManager()

    @Published var profiles: [AppProfile] = [] {
        didSet { save() }
    }

    private let storageKey = "HeadFlow_AppProfiles"

    private init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: storageKey) else { return }

        do {
            let decoded = try JSONDecoder().decode([AppProfile].self, from: data)
            self.profiles = decoded
        } catch {
            print("ProfileManager: failed to decode profiles: \(error)")
            self.profiles = []
        }
    }

    private func save() {
        let defaults = UserDefaults.standard
        do {
            let data = try JSONEncoder().encode(profiles)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("ProfileManager: failed to encode profiles: \(error)")
        }
    }

    // MARK: - Lookup

    func profile(for bundleID: String) -> AppProfile? {
        profiles.first { $0.bundleIdentifier == bundleID }
    }

    // MARK: - Editing

    /// Create or update a profile for the current frontmost app.
    func addOrUpdateProfileForFrontmostApp() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else {
            print("ProfileManager: no valid frontmost app to profile")
            return
        }

        let name = app.localizedName ?? bundleID

        if let index = profiles.firstIndex(where: { $0.bundleIdentifier == bundleID }) {
            // Update app name if needed, keep existing settings.
            profiles[index].appName = name
        } else {
            // New profile starts with current global settings as defaults.
            let new = AppProfile(
                id: UUID(),
                bundleIdentifier: bundleID,
                appName: name,
                isEnabled: true,
                scrollSensitivity: HeadFlowSettings.scrollSensitivity,
                baseLines: Double(HeadFlowSettings.baseLines()),
                deadZoneDegrees: HeadFlowSettings.deadZoneDegrees,
                maxTiltDegrees: HeadFlowSettings.maxTiltDegrees,
                scrollModeRaw: HeadFlowSettings.scrollMode.rawValue
            )
            profiles.append(new)
        }
    }

    func removeProfile(_ profile: AppProfile) {
        profiles.removeAll { $0.id == profile.id }
    }

    // MARK: - Effective config

    /// Returns the fully resolved config for the given bundle ID:
    /// per-app profile if it exists, otherwise global settings.
    func effectiveConfig(for bundleID: String?) -> HeadFlowEffectiveConfig {
        guard
            let bundleID,
            let profile = profile(for: bundleID)
        else {
            // No app-specific profile → use global.
            return HeadFlowEffectiveConfig(
                isEnabled: true, // per-app flag; global ON/OFF is separate
                scrollSensitivity: HeadFlowSettings.scrollSensitivity,
                baseLines: HeadFlowSettings.baseLines(),
                deadZoneDegrees: HeadFlowSettings.deadZoneDegrees,
                maxTiltDegrees: HeadFlowSettings.maxTiltDegrees,
                scrollMode: HeadFlowSettings.scrollMode
            )
        }

        return HeadFlowEffectiveConfig(
            isEnabled: profile.isEnabled,
            scrollSensitivity: profile.scrollSensitivity,
            baseLines: {
                let clamped = max(0.0, min(500.0, profile.baseLines))
                return Int32(clamped.rounded())
            }(),
            deadZoneDegrees: profile.deadZoneDegrees,
            maxTiltDegrees: profile.maxTiltDegrees,
            scrollMode: ScrollMode(rawValue: profile.scrollModeRaw) ?? HeadFlowSettings.scrollMode
        )
    }
}
