import ScreenSaver
import AVFoundation
import AppKit

@objc(LivePaperSaverView)
public final class LivePaperSaverView: ScreenSaverView {
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private var statusObserver: NSKeyValueObservation?
    private var isPlayerConfigured = false
    
    override public init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.cgColor
        self.animationTimeInterval = 1.0 / 30.0
    }
    
    override public func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            updatePlayerLayerFrame()
            if player == nil {
                loadAndPlayVideo()
            }
        }
    }
    
    override public func layout() {
        super.layout()
        updatePlayerLayerFrame()
    }
    
    override public func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updatePlayerLayerFrame()
    }
    
    private func updatePlayerLayerFrame() {
        guard let layer = playerLayer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = self.bounds
        CATransaction.commit()
    }
    
    override public func startAnimation() {
        super.startAnimation()
        if player == nil {
            loadAndPlayVideo()
        } else {
            player?.play()
        }
    }
    
    override public func stopAnimation() {
        super.stopAnimation()
        player?.pause()
    }
    
    private func findVideoURL() -> (url: URL?, scalingGravity: AVLayerVideoGravity) {
        var scalingGravity: AVLayerVideoGravity = .resizeAspectFill
        let homeDir = NSHomeDirectory()
        
        // 1. Bundle resources ALWAYS has full sandbox access
        if let bundlePath = Bundle(for: Self.self).path(forResource: "active_wallpaper", ofType: "mp4"),
           FileManager.default.fileExists(atPath: bundlePath) {
            return (URL(fileURLWithPath: bundlePath), scalingGravity)
        }
        
        // Candidate locations (ordered by accessibility in sandboxed legacyScreenSaver)
        let candidatePaths = [
            "\(homeDir)/Movies/LivePaper/active_wallpaper.mp4",
            "\(homeDir)/Library/Application Support/LivePaper/active_wallpaper.mp4"
        ]
        
        // Also check config.json if present
        let configPaths = [
            "\(homeDir)/Movies/LivePaper/config.json",
            "\(homeDir)/Library/Application Support/LivePaper/config.json"
        ]
        
        for configPath in configPaths {
            if let configData = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
               let json = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] {
                if let mode = json["scalingMode"] as? String, mode == "aspectFit" {
                    scalingGravity = .resizeAspect
                }
                if let rawPath = json["videoPath"] as? String, FileManager.default.fileExists(atPath: rawPath) {
                    return (URL(fileURLWithPath: rawPath), scalingGravity)
                }
            }
        }
        
        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path) {
                return (URL(fileURLWithPath: path), scalingGravity)
            }
        }
        
        return (nil, scalingGravity)
    }
    
    private func loadAndPlayVideo() {
        teardownPlayer()
        
        let (videoURLOpt, scalingGravity) = findVideoURL()
        guard let videoURL = videoURLOpt else {
            return
        }
        
        let asset = AVURLAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none
        
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        self.player = queuePlayer
        
        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = scalingGravity
        layer.frame = bounds
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        self.layer?.addSublayer(layer)
        self.playerLayer = layer
        
        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak queuePlayer] playerItem, _ in
            if playerItem.status == .readyToPlay {
                DispatchQueue.main.async {
                    queuePlayer?.play()
                }
            }
        }
        
        queuePlayer.play()
    }
    
    private func teardownPlayer() {
        statusObserver?.invalidate()
        statusObserver = nil
        
        playerLooper?.disableLooping()
        playerLooper = nil
        
        player?.pause()
        player?.removeAllItems()
        player = nil
        
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    override public func animateOneFrame() {
        // GPU driven via AVPlayerLayer
    }
    
    override public var hasConfigureSheet: Bool {
        return false
    }
    
    deinit {
        teardownPlayer()
    }
}
