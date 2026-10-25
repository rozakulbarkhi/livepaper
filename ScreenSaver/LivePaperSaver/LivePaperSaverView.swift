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
        
        guard let defaults = UserDefaults(suiteName: "com.livepaper.macos"),
              let configData = defaults.data(forKey: "com.livepaper.configuration") else {
            return
        }
        
        var targetURL: URL?
        var scalingGravity: AVLayerVideoGravity = .resizeAspectFill
        
        do {
            if let json = try JSONSerialization.jsonObject(with: configData) as? [String: Any] {
                if let mode = json["scalingMode"] as? String, mode == "aspectFit" {
                    scalingGravity = .resizeAspect
                }
                
                if let bookmarkString = json["videoBookmark"] as? String,
                   let bookmarkData = Data(base64Encoded: bookmarkString) {
                    var isStale = false
                    targetURL = try? URL(
                        resolvingBookmarkData: bookmarkData,
                        options: .withSecurityScope,
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    )
                }
                
                if targetURL == nil, let path = json["videoPath"] as? String {
                    targetURL = URL(fileURLWithPath: path)
                }
            }
        } catch {
            return
        }
        
        guard let videoURL = targetURL, FileManager.default.fileExists(atPath: videoURL.path) else {
            return
        }
        
        _ = videoURL.startAccessingSecurityScopedResource()
        
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
        // AVPlayerLayer handles video frame composition on GPU
    }
    
    override public var hasConfigureSheet: Bool {
        return false
    }
}
