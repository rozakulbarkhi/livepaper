import ScreenSaver
import AVFoundation
import AppKit

@objc(LivePaperSaverView)
public final class LivePaperSaverView: ScreenSaverView {
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    
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
    
    override public func startAnimation() {
        super.startAnimation()
        loadAndPlayVideo()
    }
    
    override public func stopAnimation() {
        super.stopAnimation()
        teardownPlayer()
    }
    
    private func loadAndPlayVideo() {
        teardownPlayer()
        
        let homeDir = NSHomeDirectory()
        let appSupportPath = "\(homeDir)/Library/Application Support/LivePaper"
        let activeVideoPath = "\(appSupportPath)/active_wallpaper.mp4"
        let configPath = "\(appSupportPath)/config.json"
        
        var targetURL: URL?
        var scalingGravity: AVLayerVideoGravity = .resizeAspectFill
        
        if let configData = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
           let json = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] {
            if let mode = json["scalingMode"] as? String, mode == "aspectFit" {
                scalingGravity = .resizeAspect
            }
            if let rawPath = json["videoPath"] as? String, FileManager.default.fileExists(atPath: rawPath) {
                targetURL = URL(fileURLWithPath: rawPath)
            }
        }
        
        // If rawPath isn't accessible due to sandbox, fall back to active_wallpaper.mp4 in Application Support
        if targetURL == nil || !FileManager.default.fileExists(atPath: targetURL!.path) {
            if FileManager.default.fileExists(atPath: activeVideoPath) {
                targetURL = URL(fileURLWithPath: activeVideoPath)
            }
        }
        
        guard let videoURL = targetURL else {
            return
        }
        
        let item = AVPlayerItem(url: videoURL)
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
        
        queuePlayer.play()
    }
    
    private func teardownPlayer() {
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
        // AVPlayerLayer handles GPU composition
    }
    
    override public var hasConfigureSheet: Bool {
        return false
    }
}
