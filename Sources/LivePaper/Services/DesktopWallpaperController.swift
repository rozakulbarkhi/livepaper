import AppKit
import AVFoundation

public final class DesktopWallpaperController: NSObject, WallpaperPlayerDelegate, DisplayMonitorDelegate, PowerMonitorDelegate, @unchecked Sendable {
    public static let shared = DesktopWallpaperController()
    
    private let player = WallpaperPlayer()
    private let displayMonitor = DisplayMonitorService()
    private let powerMonitor = PowerMonitorService.shared
    private var wallpaperWindows: [DesktopWallpaperWindow] = []
    
    private var currentURL: URL?
    private var currentScalingMode: VideoScalingMode = .aspectFill
    private var isPlayingWallpaper = false
    public var pauseOnBatteryEnabled = false
    
    public var onStatusChanged: (@Sendable (WallpaperStatus) -> Void)?
    
    private override init() {
        super.init()
        player.delegate = self
        displayMonitor.delegate = self
        powerMonitor.delegate = self
    }
    
    @MainActor
    public func startWallpaper(url: URL, scalingMode: VideoScalingMode, loop: Bool = true, pauseOnBattery: Bool = false) async throws {
        self.currentURL = url
        self.currentScalingMode = scalingMode
        self.pauseOnBatteryEnabled = pauseOnBattery
        
        onStatusChanged?(.loading)
        
        // Load the new video asset first before touching windows
        try await player.loadVideo(url: url, loop: loop, muted: true)
        
        setupWindows()
        
        if pauseOnBattery && powerMonitor.isOnBattery {
            onStatusChanged?(.paused)
        } else {
            player.play()
            isPlayingWallpaper = true
            onStatusChanged?(.playing(videoName: url.lastPathComponent))
        }
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
        let windowsToClean = wallpaperWindows
        wallpaperWindows.removeAll()
        
        for window in windowsToClean {
            window.prepareForRemoval()
            window.orderOut(nil)
            window.close()
        }
    }
    
    // MARK: - PowerMonitorDelegate
    
    public func powerSourceDidChange(isOnBattery: Bool) {
        Task { @MainActor in
            guard self.pauseOnBatteryEnabled, self.isPlayingWallpaper else { return }
            if isOnBattery {
                print("[DesktopWallpaperController] Running on battery power. Pausing live wallpaper...")
                self.player.pause()
                self.onStatusChanged?(.paused)
            } else {
                print("[DesktopWallpaperController] Connected to AC power. Resuming live wallpaper...")
                self.player.play()
                if let name = self.currentURL?.lastPathComponent {
                    self.onStatusChanged?(.playing(videoName: name))
                }
            }
        }
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
                if self.pauseOnBatteryEnabled && self.powerMonitor.isOnBattery {
                    return
                }
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
                if self.pauseOnBatteryEnabled && self.powerMonitor.isOnBattery {
                    return
                }
                self.player.play()
            }
        }
    }
}
