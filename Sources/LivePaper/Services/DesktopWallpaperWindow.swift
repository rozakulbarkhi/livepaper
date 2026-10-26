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
        
        // Desktop window level (behind desktop icons during normal desktop use)
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))
        
        // Ensure seamless display on all spaces, full screens, and across system spaces
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
    
    public func setLockScreenMode(_ isLocked: Bool) {
        if isLocked {
            // Elevate window level above user-space applications (shielding / lock level)
            // kCGShieldingWindowLevel is 2147483628, placed just under the secure login dialog
            self.level = NSWindow.Level(Int(CGShieldingWindowLevel()) - 1)
            self.orderFrontRegardless()
        } else {
            // Restore desktop level when unlocked (behind Finder desktop icons)
            self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))
            self.orderFront(nil)
        }
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
