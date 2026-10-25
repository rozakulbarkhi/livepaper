import SwiftUI

public struct ContentView: View {
    @ObservedObject var settings: WallpaperSettings
    @State private var errorMessage: String?
    @State private var isProcessing = false
    @State private var isTargetedForDrop = false
    
    public init(settings: WallpaperSettings) {
        self.settings = settings
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LivePaper")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("Native macOS Live Wallpaper Engine")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    statusBadge
                }
                
                // Error banner if any
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text(error)
                            .font(.callout)
                        Spacer()
                        Button("Dismiss") {
                            errorMessage = nil
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(8)
                }
                
                // Video Picker & Drag Drop Zone
                VStack(spacing: 8) {
                    VideoPickerView(settings: settings, errorMessage: $errorMessage)
                    
                    // Drop area indicator
                    HStack {
                        Image(systemName: "arrow.down.doc")
                        Text("Or drag & drop any MP4/MOV video here")
                    }
                    .font(.caption)
                    .foregroundColor(isTargetedForDrop ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isTargetedForDrop ? Color.accentColor : Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    )
                }
                .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
                    handleDrop(providers: providers)
                }
                
                // Recent Wallpapers (if available)
                if !settings.configuration.recentWallpapers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Wallpapers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(settings.configuration.recentWallpapers) { item in
                                    Button(action: { selectRecent(item) }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "film")
                                                .font(.caption2)
                                            Text(item.name)
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(item.path == settings.configuration.videoPath ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                
                // Preview
                WallpaperPreviewView(
                    url: resolvedVideoURL(),
                    scalingMode: settings.configuration.scalingMode
                )
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: applyWallpaper) {
                        Label(
                            settings.status.isPlaying ? "Restart Wallpaper" : "Apply Wallpaper",
                            systemImage: "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(settings.configuration.videoPath == nil || isProcessing)
                    
                    Button(action: stopWallpaper) {
                        Label("Stop Wallpaper", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(!settings.status.isPlaying || isProcessing)
                }
                
                Divider()
                
                // Settings
                SettingsView(settings: settings, errorMessage: $errorMessage)
            }
            .padding(24)
        }
        .frame(minWidth: 540, idealWidth: 600, minHeight: 650, idealHeight: 740)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(settings.status.statusDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    private var statusColor: Color {
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
    
    private func resolvedVideoURL() -> URL? {
        if let bookmark = settings.configuration.videoBookmark {
            let (url, _) = WallpaperPersistenceService.shared.resolveBookmark(data: bookmark)
            if let url = url { return url }
        }
        if let path = settings.configuration.videoPath {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    private func selectRecent(_ item: RecentWallpaperItem) {
        let url = URL(fileURLWithPath: item.path)
        let bookmark = item.bookmark ?? WallpaperPersistenceService.shared.createBookmark(for: url)
        settings.updateVideo(url: url, bookmark: bookmark)
        applyWallpaper()
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            let ext = url.pathExtension.lowercased()
            guard ["mp4", "mov", "m4v"].contains(ext) else {
                Task { @MainActor in
                    self.errorMessage = "Please drop an MP4 or MOV video file."
                }
                return
            }
            
            Task { @MainActor in
                let bookmark = WallpaperPersistenceService.shared.createBookmark(for: url)
                self.settings.updateVideo(url: url, bookmark: bookmark)
                self.errorMessage = nil
                self.applyWallpaper()
            }
        }
        return true
    }
    
    private func applyWallpaper() {
        guard let url = resolvedVideoURL() else {
            errorMessage = "No valid video file could be located."
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                try await DesktopWallpaperController.shared.startWallpaper(
                    url: url,
                    scalingMode: settings.configuration.scalingMode,
                    loop: settings.configuration.isLooping,
                    pauseOnBattery: settings.configuration.pauseOnBattery,
                    applyOnLockScreen: settings.configuration.applyOnLockScreen
                )
                isProcessing = false
            } catch {
                isProcessing = false
                errorMessage = "Failed to start wallpaper: \(error.localizedDescription)"
                settings.status = .error(message: error.localizedDescription)
            }
        }
    }
    
    private func stopWallpaper() {
        DesktopWallpaperController.shared.stopWallpaper()
        errorMessage = nil
    }
}
