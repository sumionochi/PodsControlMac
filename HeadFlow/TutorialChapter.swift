//  TutorialChapter.swift

import Foundation

/// Metadata for the single HeadFlow tutorial video
enum TutorialMetadata {
    /// Your Mux Playback ID (the thing that becomes https://stream.mux.com/<playbackId>.m3u8)
    static let playbackId = "Th6zAe3AM3uIKc50202hRLokW88SF5q8N1UHJcJQLHhmw"

    /// Asset ID (no longer used for chapters, but you can keep it here)
    static let assetId = "0000I025NN8K02RI02sn00vEflNVWRudq8LDGLwkswO4fg21U"

    static let title = "HeadFlow Tutorial"
    static let description = """
    Learn everything about HeadFlow – from setup to advanced features. \
    Master hands-free control of your Mac with AirPods.
    """
}

struct TutorialChapter: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let startTime: Double
    let duration: Double
    let summary: String?
    /// String used by the UI to find a chapter for a given screen/tab
    let relatedView: String?
}

/// Central place to access tutorial metadata + chapters
enum TutorialManager {

    static let playbackId = TutorialMetadata.playbackId

    /// Hard-coded chapters based on your SRT timestamps
    static let chapters: [TutorialChapter] = [

        // (00:09) Welcome.
        // (00:09) Please enable all your permissions.
        TutorialChapter(
            id: "welcome",
            title: "Welcome & Permissions",
            startTime: 9,          // 00:09
            duration: 32,          // until ~00:41
            summary: "Intro to HeadFlow and why microphone, motion and accessibility permissions are required.",
            relatedView: "welcome"
        ),

        // (00:41) Wear your Apple earphones...
        // (00:50) Open the app and check the status bar.
        TutorialChapter(
            id: "setup",
            title: "Headphones & Setup",
            startTime: 41,         // 00:41
            duration: 15,          // until ~00:56
            summary: "Wear supported Apple headphones and verify the status bar indicators inside HeadFlow.",
            relatedView: "setup"
        ),

        // (00:56) In cursor mode…
        // (01:05) Use command key…
        // (01:10) Use control and command key…
        // (01:16) Move head up or down to scroll.
        TutorialChapter(
            id: "basic-scrolling",
            title: "Cursor Control & Scrolling",
            startTime: 56,         // 00:56
            duration: 57,          // until ~01:53
            summary: "Move your head to control the cursor, use ⌘ for clicks, ⌃+⌘ for drag, and tilt to scroll.",
            relatedView: "basic-scrolling"
        ),

        // (01:53) Open the on-device dictation…
        // (02:02) Custom phrases are swapped…
        // + the demo lines (“Hi, how are you?” etc.)
        TutorialChapter(
            id: "voice-dictation",
            title: "Dictation & Custom Phrases",
            startTime: 113,        // 01:53
            duration: 44,          // until ~02:37
            summary: "Turn on on-device dictation, speak your text, and see custom phrases expand in real time.",
            relatedView: "voice-dictation"
        ),

        // (02:37) Decide the actions to be controlled by gesture control…
        TutorialChapter(
            id: "gestures",
            title: "Gesture Control (Look Left / Right)",
            startTime: 157,        // 02:37
            duration: 39,          // until ~03:16
            summary: "Choose which system actions are triggered when you look left or right using gesture control.",
            relatedView: "gestures"
        ),

        // (03:16) Custom settings and shortcuts can be managed…
        TutorialChapter(
            id: "keyboard-shortcuts",
            title: "Preferences & Shortcuts",
            startTime: 196,        // 03:16
            duration: 43,          // until ~03:59
            summary: "Configure global settings and keyboard shortcuts from the preferences panel.",
            relatedView: "keyboard-shortcuts"
        ),

        // (03:59) Users can even manage app-specific settings.
        TutorialChapter(
            id: "per-app-profiles",
            title: "Per-App Profiles & App Settings",
            startTime: 239,        // 03:59
            duration: 40,          // approximate tail of video
            summary: "Set up app-specific behaviour so HeadFlow feels tuned for each app you use.",
            relatedView: "per-app-profiles"
        )
    ]

    /// Used by the different tabs/screens to open the right part of the video
    static func getChapter(for viewIdentifier: String) -> TutorialChapter? {
        chapters.first { $0.relatedView == viewIdentifier }
    }

    /// Used by the player while scrubbing / updating current chapter highlight
    static func chapter(forTime time: Double) -> TutorialChapter? {
        // last chapter whose startTime is <= current time
        chapters.last { time >= $0.startTime }
    }
}
