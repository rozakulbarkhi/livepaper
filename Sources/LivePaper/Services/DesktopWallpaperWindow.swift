import AppKit
import AVFoundation

public final class DesktopWallpaperWindow: NSWindow {
    private let playerView: DesktopPlayerView
    
    public init(screen: NSScreen, player: AVPlayer, scalingMode: VideoScalingMode) {
        self.playerView = DesktopPlayerView(player: player, scalingMode: scalingMode)
        
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Prevent window release on close crash
        self.isReleasedWhenClosed = false
        self.isOpaque = true
        self.backgroundColor = .black
        self.hasShadow = false
        
        // Set window level to desktop level (just above desktop background, below icons)
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))
        
        // Ensure seamless display on all spaces and full screens
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]
        
        // Pass mouse/keyboard events through to Finder and desktop icons
        self.ignoresMouseEvents = true
        self.acceptsMouseMovedEvents = false
        
        self.contentView = playerView
        self.setFrame(screen.frame, display: true)
    }
    
    public func updateScalingMode(_ mode: VideoScalingMode) {
        playerView.updateScalingMode(mode)
    }
    
    public func prepareForRemoval() {
        playerView.detachPlayer()
        self.contentView = nil
    }
    
    override public var canBecomeKey: Bool { false }
    override public var canBecomeMain: Bool { false }
}

public final class DesktopPlayerView: NSView {
    private let playerLayer = AVPlayerLayer()
    
    public init(player: AVPlayer, scalingMode: VideoScalingMode) {
        super.init(frame: .zero)
        self.wantsLayer = true
        
        playerLayer.player = player
        playerLayer.videoGravity = scalingMode.videoGravity
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        if let layer = self.layer {
            layer.backgroundColor = NSColor.black.cgColor
            layer.addSublayer(playerLayer)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func detachPlayer() {
        playerLayer.player = nil
        playerLayer.removeFromSuperlayer()
    }
    
    override public func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
    
    public func updateScalingMode(_ mode: VideoScalingMode) {
        playerLayer.videoGravity = mode.videoGravity
    }
}
