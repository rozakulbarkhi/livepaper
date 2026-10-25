import SwiftUI

public struct ContentView: View {
    @ObservedObject var settings: WallpaperSettings
    @State private var errorMessage: String?
    @State private var isProcessing = false
    
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
                
                // Video Picker
                VideoPickerView(settings: settings, errorMessage: $errorMessage)
                
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
        .frame(minWidth: 540, idealWidth: 600, minHeight: 650, idealHeight: 720)
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
                    loop: settings.configuration.isLooping
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
