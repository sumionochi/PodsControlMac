//
//  MuxTutorialPlayer.swift
//  PodsControlMac / HeadFlow
//
//  Mux Video Player Component for Tutorial Videos
//  Supports chapter-based navigation and multi-language captions
//

import SwiftUI
import AVKit
import AVFoundation

// MARK: - Mux Video Player View

/// A reusable Mux video player component with chapter navigation
struct MuxTutorialPlayer: View {
    // MARK: - Properties
    
    let chapter: TutorialChapter
    let showChapterList: Bool
    let onDismiss: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlayerReady = false
    @State private var currentTime: Double = 0
    @State private var showControls = true
    
    // MARK: - Initialization
    
    init(
        chapter: TutorialChapter,
        showChapterList: Bool = true,
        onDismiss: @escaping () -> Void
    ) {
        self.chapter = chapter
        self.showChapterList = showChapterList
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            tutorialHeader
            
            HStack(spacing: 16) {
                // Video player
                VStack(spacing: 12) {
                    videoPlayerView
                    
                    // Chapter info
                    chapterInfoCard
                }
                .frame(maxWidth: .infinity)
                
                // Chapter list (optional)
                if showChapterList {
                    chapterListSidebar
                        .frame(width: 280)
                }
            }
            .padding(20)
        }
        .frame(minWidth: showChapterList ? 900 : 640, minHeight: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    // MARK: - Header
    
    private var tutorialHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("HeadFlow Tutorial")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(chapter.title)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close tutorial")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Video Player
    
    private var videoPlayerView: some View {
        ZStack {
            if let player = player {
                VideoPlayerView(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            } else {
                // Loading placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.9))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading tutorial...")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    )
            }
        }
    }
    
    // MARK: - Chapter Info Card
    
    private var chapterInfoCard: some View {
        HStack(spacing: 12) {
            // Chapter icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title)
                    .font(.system(size: 13, weight: .semibold))
                
                if let summary = chapter.summary {
                    Text(summary)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Time indicator
            Text(chapter.formattedTime)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    // MARK: - Chapter List Sidebar
    
    private var chapterListSidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Chapters")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(TutorialManager.chapters) { chapterItem in
                        chapterRowButton(chapterItem)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private func chapterRowButton(_ chapterItem: TutorialChapter) -> some View {
        Button(action: {
            jumpToChapter(chapterItem)
        }) {
            HStack(spacing: 10) {
                // Status indicator
                Circle()
                    .fill(chapterItem.id == chapter.id ? Color.accentColor : Color.clear)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(chapterItem.title)
                        .font(.system(size: 12, weight: chapterItem.id == chapter.id ? .semibold : .regular))
                        .foregroundColor(chapterItem.id == chapter.id ? .primary : .secondary)
                    
                    Text(chapterItem.formattedTime)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if chapterItem.id == chapter.id {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(chapterItem.id == chapter.id ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Player Setup
    
    private func setupPlayer() {
        // Construct Mux HLS URL
        let playbackId = TutorialManager.playbackId
        guard let url = URL(string: "https://stream.mux.com/\(playbackId).m3u8") else {
            print("❌ Invalid Mux URL")
            return
        }
        
        // Create AVPlayer
        let avPlayer = AVPlayer(url: url)
        
        // Configure for better playback
        avPlayer.automaticallyWaitsToMinimizeStalling = true
        
        // Wait for player to be ready, then seek to chapter start time
        let observation = avPlayer.observe(\.status) { player, _ in
            if player.status == .readyToPlay {
                self.isPlayerReady = true
                
                // Seek to chapter start time
                let startTime = CMTime(seconds: self.chapter.startTime, preferredTimescale: 600)
                player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
                    if finished {
                        print("✅ Seeked to chapter: \(self.chapter.title) at \(self.chapter.startTime)s")
                    }
                }
            }
        }
        
        // Store player
        self.player = avPlayer
        
        // Start playback automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            avPlayer.play()
        }
    }
    
    private func jumpToChapter(_ targetChapter: TutorialChapter) {
        guard let player = player else { return }
        
        let startTime = CMTime(seconds: targetChapter.startTime, preferredTimescale: 600)
        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            if finished {
                print("✅ Jumped to chapter: \(targetChapter.title)")
                player.play()
            }
        }
    }
}

// MARK: - AVPlayer Wrapper for SwiftUI (macOS)

/// Wraps AVPlayerView for macOS SwiftUI
struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .inline
        playerView.showsFullScreenToggleButton = true
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        // Update if needed
    }
}

// MARK: - Compact Tutorial Button

/// A compact button to show tutorial for a specific view
struct TutorialButton: View {
    let chapter: TutorialChapter
    @State private var showTutorial = false
    
    var body: some View {
        Button(action: {
            showTutorial = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 14))
                Text("Watch Tutorial")
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.1))
            )
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .help("Watch tutorial for \(chapter.title)")
        .sheet(isPresented: $showTutorial) {
            MuxTutorialPlayer(
                chapter: chapter,
                showChapterList: true,
                onDismiss: {
                    showTutorial = false
                }
            )
        }
    }
}

// MARK: - Tutorial Card (Larger Version)

/// A larger tutorial card with more information
struct TutorialCard: View {
    let chapter: TutorialChapter
    @State private var showTutorial = false
    
    var body: some View {
        Button(action: {
            showTutorial = true
        }) {
            HStack(spacing: 16) {
                // Video thumbnail placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 56)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(chapter.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(chapter.formattedTime)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    if let summary = chapter.summary {
                        Text(summary)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showTutorial) {
            MuxTutorialPlayer(
                chapter: chapter,
                showChapterList: true,
                onDismiss: {
                    showTutorial = false
                }
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MuxTutorialPlayer_Previews: PreviewProvider {
    static var previews: some View {
        MuxTutorialPlayer(
            chapter: TutorialManager.chapters[0],
            showChapterList: true,
            onDismiss: {}
        )
    }
}
#endif