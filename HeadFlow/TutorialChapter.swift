//
//  TutorialChapters.swift
//  PodsControlMac / HeadFlow
//
//  Mux Video Tutorial Integration
//  This file defines all tutorial chapters and their metadata
//

import Foundation

// MARK: - Tutorial Chapter Model

/// Represents a single chapter in the tutorial video
struct TutorialChapter: Identifiable, Codable {
    let id: String
    let title: String
    let startTime: Double      // seconds
    let duration: Double       // seconds
    let summary: String?       // AI-generated summary from Mux
    let relatedView: String?   // Which view this tutorial is for
    
    var endTime: Double {
        startTime + duration
    }
    
    var formattedTime: String {
        let minutes = Int(startTime) / 60
        let seconds = Int(startTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Tutorial Manager

/// Manages tutorial video playback and chapter navigation
class TutorialManager {
    static let shared = TutorialManager()
    
    // MARK: - Mux Configuration
    
    /// Your Mux Playback ID - Replace with actual value after uploading tutorial
    static let playbackId = "YOUR_MUX_PLAYBACK_ID"
    
    /// Your Mux Asset ID - For fetching chapters dynamically
    static let assetId = "YOUR_MUX_ASSET_ID"
    
    // MARK: - Tutorial Chapters
    
    /// All chapters in the tutorial video
    /// These timestamps should match the actual video chapters
    /// You can auto-fetch these from Mux API or define them manually
    static let chapters: [TutorialChapter] = [
        TutorialChapter(
            id: "welcome",
            title: "Welcome & Getting Started",
            startTime: 0,
            duration: 90,
            summary: "Introduction to HeadFlow and overview of what the app can do. Learn about hands-free control with AirPods and basic features.",
            relatedView: "welcome"
        ),
        
        TutorialChapter(
            id: "setup",
            title: "Initial Setup & Permissions",
            startTime: 90,
            duration: 120,
            summary: "Step-by-step guide through the permission setup process. Learn what each permission does and why it's needed.",
            relatedView: "setup"
        ),
        
        TutorialChapter(
            id: "basic-scrolling",
            title: "Basic Scrolling Controls",
            startTime: 210,
            duration: 150,
            summary: "Master head-driven scrolling. Adjust sensitivity, deadzone, and learn different scrolling modes for your workflow.",
            relatedView: "controls"
        ),
        
        TutorialChapter(
            id: "gestures",
            title: "Head Gestures",
            startTime: 360,
            duration: 120,
            summary: "Configure head tilt gestures for quick actions. Set up left/right/forward/backward tilts for custom commands.",
            relatedView: "gestures"
        ),
        
        TutorialChapter(
            id: "voice-dictation",
            title: "Voice Dictation & Commands",
            startTime: 480,
            duration: 140,
            summary: "Set up voice dictation and custom voice commands. Learn auto-commit settings and voice-activated shortcuts.",
            relatedView: "voice"
        ),
        
        TutorialChapter(
            id: "per-app-profiles",
            title: "Per-App Customization",
            startTime: 620,
            duration: 100,
            summary: "Create custom profiles for different apps. Different sensitivity for reading vs coding vs browsing.",
            relatedView: "apps"
        ),
        
        TutorialChapter(
            id: "keyboard-shortcuts",
            title: "Keyboard Shortcuts",
            startTime: 720,
            duration: 80,
            summary: "Configure global keyboard shortcuts for quick access. Toggle scrolling, calibrate, and open preferences instantly.",
            relatedView: "shortcuts"
        ),
        
        TutorialChapter(
            id: "advanced-tips",
            title: "Advanced Tips & Tricks",
            startTime: 800,
            duration: 100,
            summary: "Pro tips for power users. Advanced cursor control, fine-tuning, and workflow optimization.",
            relatedView: "advanced"
        ),
        
        TutorialChapter(
            id: "troubleshooting",
            title: "Troubleshooting & FAQ",
            startTime: 900,
            duration: 120,
            summary: "Common issues and solutions. Connection problems, permission issues, and performance optimization.",
            relatedView: "troubleshooting"
        )
    ]
    
    // MARK: - Chapter Lookup Methods
    
    /// Get chapter for a specific view
    static func getChapter(for viewIdentifier: String) -> TutorialChapter? {
        return chapters.first { $0.relatedView == viewIdentifier }
    }
    
    /// Get chapter by ID
    static func getChapter(byId id: String) -> TutorialChapter? {
        return chapters.first { $0.id == id }
    }
    
    /// Get all chapters for a specific view (multiple chapters can relate to same view)
    static func getChapters(for viewIdentifier: String) -> [TutorialChapter] {
        return chapters.filter { $0.relatedView == viewIdentifier }
    }
    
    /// Get chapter that contains a specific timestamp
    static func getChapter(at time: Double) -> TutorialChapter? {
        return chapters.first { chapter in
            time >= chapter.startTime && time < chapter.endTime
        }
    }
    
    // MARK: - Dynamic Chapter Fetching from Mux
    
    /// Fetch chapters dynamically from Mux API
    /// This requires your Mux API credentials
    static func fetchChaptersFromMux() async throws -> [TutorialChapter] {
        // TODO: Implement Mux API call to fetch chapters
        // This would use the Mux Assets API to get chapter data
        
        guard let url = URL(string: "https://api.mux.com/video/v1/assets/\(assetId)") else {
            throw NSError(domain: "TutorialManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // You would need to add Mux credentials here
        // For now, return the hardcoded chapters
        return chapters
    }
}

// MARK: - Chapter Summary Provider

/// Handles AI-generated chapter summaries
/// This can be extended to fetch summaries from Mux AI or OpenAI
class ChapterSummaryProvider {
    
    /// Generate summaries for all chapters using AI
    /// Can use Mux captions + GPT-4 to auto-generate
    static func generateSummaries() async throws -> [String: String] {
        // TODO: Implement AI summary generation
        // 1. Fetch captions from Mux: https://stream.mux.com/{playbackId}/text/{trackId}.vtt
        // 2. Send to GPT-4 with chapter timestamps
        // 3. Generate concise summaries for each chapter
        
        return [:]
    }
}

// MARK: - Tutorial Video Metadata

/// Additional metadata about the tutorial video
struct TutorialMetadata {
    static let title = "Complete HeadFlow Tutorial"
    static let description = "Learn everything about HeadFlow - from setup to advanced features. Master hands-free control of your Mac with AirPods."
    static let duration = 1020 // 17 minutes (17:00)
    static let thumbnailTime: Double = 5 // Show thumbnail at 5 seconds
    static let accentColor = "#007AFF" // Match app accent color
    
    /// Languages available for captions
    static let availableLanguages = [
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "ja": "Japanese",
        "hi": "Hindi"
    ]
}