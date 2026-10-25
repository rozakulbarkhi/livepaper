import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var settings: WallpaperSettings
    @Environment(\.openWindow) private var openWindow
    
    public init(settings: WallpaperSettings) {
        self.settings = settings
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header / Status
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(statusIndicatorColor)
                        .frame(width: 8, height: 8)
                    Text("LivePaper")
                        .font(.headline)
                    Spacer()
                }
                
                if let videoName = settings.configuration.videoName {
                    Text(videoName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("No wallpaper active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            
            Divider()
            
            // Quick Actions
            Group {
                if settings.status.isPlaying {
                    Button(action: togglePlayPause) {
                        Label("Pause Wallpaper", systemImage: "pause.fill")
                    }
                } else if settings.configuration.videoPath != nil {
                    Button(action: togglePlayPause) {
                        Label("Resume Wallpaper", systemImage: "play.fill")
                    }
                }
                
                if settings.status.isPlaying {
                    Button(action: stopWallpaper) {
                        Label("Stop Wallpaper", systemImage: "stop.fill")
                    }
                }
                
                Divider()
                
                Button(action: openMainWindow) {
                    Label("Open LivePaper Settings…", systemImage: "slider.horizontal.3")
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button(role: .destructive, action: quitApp) {
                    Label("Quit LivePaper", systemImage: "power")
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
        }
        .frame(width: 240)
    }
    
    private var statusIndicatorColor: Color {
        switch settings.status {
        case .idle:
            return .gray
        case .loading:
            return .orange
        case .playing:
            return .green
        case .paused:
            return .yellow
        case .error:
            return .red
        }
    }
    
    private func togglePlayPause() {
        if settings.status.isPlaying {
            DesktopWallpaperController.shared.stopWallpaper()
        } else {
            applyActiveVideo()
        }
    }
    
    private func stopWallpaper() {
        DesktopWallpaperController.shared.stopWallpaper()
    }
    
    private func applyActiveVideo() {
        var targetURL: URL?
        if let bookmark = settings.configuration.videoBookmark {
            let (url, _) = WallpaperPersistenceService.shared.resolveBookmark(data: bookmark)
            targetURL = url
        }
        if targetURL == nil, let path = settings.configuration.videoPath {
            targetURL = URL(fileURLWithPath: path)
        }
        
        guard let url = targetURL else { return }
        
        Task {
            do {
                try await DesktopWallpaperController.shared.startWallpaper(
                    url: url,
                    scalingMode: settings.configuration.scalingMode,
                    loop: settings.configuration.isLooping
                )
            } catch {
                settings.status = .error(message: error.localizedDescription)
            }
        }
    }
    
    private func openMainWindow() {
        // Bring all app windows to front
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { !($0 is DesktopWallpaperWindow) }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main-window")
        }
    }
    
    private func quitApp() {
        DesktopWallpaperController.shared.stopWallpaper()
        NSApplication.shared.terminate(nil)
    }
}
