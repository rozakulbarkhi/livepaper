import SwiftUI
import AppKit

@main
struct LivePaperApp: App {
    @StateObject private var settings = WallpaperSettings()
    
    init() {}
    
    var body: some Scene {
        Window("LivePaper", id: "main-window") {
            ContentView(settings: settings)
                .onAppear {
                    setupApp()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 600, height: 740)
        
        MenuBarExtra("LivePaper", systemImage: "sparkles.tv") {
            MenuBarView(settings: settings)
        }
        .menuBarExtraStyle(.window)
    }
    
    private func setupApp() {
        DesktopWallpaperController.shared.onStatusChanged = { [weak settings] status in
            Task { @MainActor in
                settings?.status = status
            }
        }
        
        // Auto-play if enabled and video exists
        if settings.configuration.autoPlayOnLaunch,
           let path = settings.configuration.videoPath {
            var targetURL: URL?
            if let bookmark = settings.configuration.videoBookmark {
                let (url, _) = WallpaperPersistenceService.shared.resolveBookmark(data: bookmark)
                targetURL = url
            }
            if targetURL == nil {
                targetURL = URL(fileURLWithPath: path)
            }
            
            if let url = targetURL, FileManager.default.fileExists(atPath: url.path) {
                Task {
                    do {
                        try await DesktopWallpaperController.shared.startWallpaper(
                            url: url,
                            scalingMode: settings.configuration.scalingMode,
                            loop: settings.configuration.isLooping,
                            pauseOnBattery: settings.configuration.pauseOnBattery
                        )
                    } catch {
                        print("[LivePaperApp] Auto-play failed: \(error.localizedDescription)")
                        settings.status = .error(message: error.localizedDescription)
                    }
                }
            }
        }
    }
}
