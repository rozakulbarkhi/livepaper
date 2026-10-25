import AppKit
import AVFoundation

public final class DesktopWallpaperController: NSObject, WallpaperPlayerDelegate, DisplayMonitorDelegate, @unchecked Sendable {
    public static let shared = DesktopWallpaperController()
    
    private let player = WallpaperPlayer()
    private let displayMonitor = DisplayMonitorService()
    private var wallpaperWindows: [DesktopWallpaperWindow] = []
    
    private var currentURL: URL?
    private var currentScalingMode: VideoScalingMode = .aspectFill
    private var isPlayingWallpaper = false
    
    public var onStatusChanged: (@Sendable (WallpaperStatus) -> Void)?
    
    private override init() {
        super.init()
        player.delegate = self
        displayMonitor.delegate = self
    }
    
    @MainActor
    public func startWallpaper(url: URL, scalingMode: VideoScalingMode, loop: Bool = true) async throws {
        self.currentURL = url
        self.currentScalingMode = scalingMode
        
        onStatusChanged?(.loading)
        
        try await player.loadVideo(url: url, loop: loop, muted: true)
        
        setupWindows()
        player.play()
        isPlayingWallpaper = true
        
        onStatusChanged?(.playing(videoName: url.lastPathComponent))
    }
    
    @MainActor
    public func stopWallpaper() {
        tearDownWindows()
        player.stop()
        isPlayingWallpaper = false
        currentURL = nil
        onStatusChanged?(.idle)
    }
    
    @MainActor
    public func setScalingMode(_ mode: VideoScalingMode) {
        self.currentScalingMode = mode
        for window in wallpaperWindows {
            window.updateScalingMode(mode)
        }
    }
    
    @MainActor
    private func setupWindows() {
        tearDownWindows()
        guard let avPlayer = player.player else { return }
        
        for screen in NSScreen.screens {
            let window = DesktopWallpaperWindow(screen: screen, player: avPlayer, scalingMode: currentScalingMode)
            window.orderFront(nil)
            wallpaperWindows.append(window)
        }
    }
    
    @MainActor
    private func tearDownWindows() {
        for window in wallpaperWindows {
            window.orderOut(nil)
            window.close()
        }
        wallpaperWindows.removeAll()
    }
    
    // MARK: - WallpaperPlayerDelegate
    
    public func wallpaperPlayer(_ player: WallpaperPlayer, didChangeStatus status: WallpaperStatus) {
        onStatusChanged?(status)
    }
    
    public func wallpaperPlayer(_ player: WallpaperPlayer, didEncounterError error: Error) {
        Task { @MainActor in
            self.stopWallpaper()
            self.onStatusChanged?(.error(message: error.localizedDescription))
        }
    }
    
    // MARK: - DisplayMonitorDelegate
    
    public func displayConfigurationDidChange() {
        Task { @MainActor in
            guard self.isPlayingWallpaper, let _ = self.player.player else { return }
            print("[DesktopWallpaperController] Screen parameters changed. Rebuilding windows...")
            self.setupWindows()
        }
    }
    
    public func systemWillSleep() {
        Task { @MainActor in
            print("[DesktopWallpaperController] System will sleep. Pausing wallpaper player...")
            self.player.pause()
        }
    }
    
    public func systemDidWake() {
        Task { @MainActor in
            print("[DesktopWallpaperController] System did wake. Resuming wallpaper player...")
            if self.isPlayingWallpaper {
                self.player.play()
            }
        }
    }
    
    public func screensDidSleep() {
        Task { @MainActor in
            print("[DesktopWallpaperController] Screens went to sleep. Pausing wallpaper...")
            self.player.pause()
        }
    }
    
    public func screensDidWake() {
        Task { @MainActor in
            print("[DesktopWallpaperController] Screens woke up. Resuming wallpaper...")
            if self.isPlayingWallpaper {
                self.player.play()
            }
        }
    }
}
