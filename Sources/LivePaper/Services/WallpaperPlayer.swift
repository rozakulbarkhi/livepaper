import Foundation
import AVFoundation

public enum WallpaperPlayerError: LocalizedError, Sendable {
    case unplayableFile(URL)
    case missingTracks
    case playbackFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .unplayableFile(let url):
            return "File is not playable by AVFoundation: \(url.lastPathComponent)"
        case .missingTracks:
            return "The selected media contains no playable video tracks."
        case .playbackFailed(let msg):
            return "Playback error: \(msg)"
        }
    }
}

public protocol WallpaperPlayerDelegate: AnyObject, Sendable {
    func wallpaperPlayer(_ player: WallpaperPlayer, didChangeStatus status: WallpaperStatus)
    func wallpaperPlayer(_ player: WallpaperPlayer, didEncounterError error: Error)
}

public final class WallpaperPlayer: @unchecked Sendable {
    public private(set) var player: AVQueuePlayer?
    public private(set) var playerLooper: AVPlayerLooper?
    public private(set) var currentURL: URL?
    public weak var delegate: WallpaperPlayerDelegate?
    
    private var isAccessingSecurityScope = false
    private var statusObserver: NSKeyValueObservation?
    
    public init() {}
    
    public func validateVideo(url: URL) async throws {
        let asset = AVURLAsset(url: url)
        let isPlayable = try await asset.load(.isPlayable)
        guard isPlayable else {
            throw WallpaperPlayerError.unplayableFile(url)
        }
        
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard !videoTracks.isEmpty else {
            throw WallpaperPlayerError.missingTracks
        }
    }
    
    public func loadVideo(url: URL, loop: Bool = true, muted: Bool = true) async throws {
        stop()
        
        if url.startAccessingSecurityScopedResource() {
            isAccessingSecurityScope = true
        }
        
        try await validateVideo(url: url)
        
        self.currentURL = url
        
        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.isMuted = muted
        queuePlayer.actionAtItemEnd = loop ? .none : .pause
        
        if loop {
            self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        }
        
        self.player = queuePlayer
        
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .failed {
                let err = item.error.map { WallpaperPlayerError.playbackFailed($0.localizedDescription) } ?? WallpaperPlayerError.playbackFailed("Unknown playback failure")
                self.delegate?.wallpaperPlayer(self, didEncounterError: err)
            }
        }
    }
    
    public func play() {
        player?.play()
    }
    
    public func pause() {
        player?.pause()
    }
    
    public func stop() {
        statusObserver?.invalidate()
        statusObserver = nil
        
        playerLooper?.disableLooping()
        playerLooper = nil
        
        player?.pause()
        player?.removeAllItems()
        player = nil
        
        if isAccessingSecurityScope, let url = currentURL {
            url.stopAccessingSecurityScopedResource()
            isAccessingSecurityScope = false
        }
        
        currentURL = nil
    }
    
    public func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }
}
