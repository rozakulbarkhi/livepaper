import SwiftUI
import AppKit
import AVFoundation

public struct WallpaperPreviewView: View {
    let url: URL?
    let scalingMode: VideoScalingMode
    
    @State private var player: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?
    
    public init(url: URL?, scalingMode: VideoScalingMode = .aspectFill) {
        self.url = url
        self.scalingMode = scalingMode
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            
            if let player = player {
                NativeVideoPlayerView(player: player, scalingMode: scalingMode)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "film")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text(url == nil ? "No Video Selected" : "Preview Unavailable")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minHeight: 220, maxHeight: 300)
        .onAppear {
            setupPreviewPlayer()
        }
        .onChange(of: url) { _, _ in
            setupPreviewPlayer()
        }
        .onDisappear {
            teardownPreviewPlayer()
        }
    }
    
    private func setupPreviewPlayer() {
        teardownPreviewPlayer()
        guard let url = url else { return }
        
        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        self.player = queuePlayer
        queuePlayer.play()
    }
    
    private func teardownPreviewPlayer() {
        playerLooper?.disableLooping()
        playerLooper = nil
        player?.pause()
        player?.removeAllItems()
        player = nil
    }
}

public struct NativeVideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    let scalingMode: VideoScalingMode
    
    public func makeNSView(context: Context) -> DesktopPlayerView {
        return DesktopPlayerView(player: player, scalingMode: scalingMode)
    }
    
    public func updateNSView(_ nsView: DesktopPlayerView, context: Context) {
        nsView.updateScalingMode(scalingMode)
    }
}
