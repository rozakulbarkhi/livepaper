import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings: WallpaperSettings
    @Binding var errorMessage: String?
    
    public init(settings: WallpaperSettings, errorMessage: Binding<String?>) {
        self.settings = settings
        self._errorMessage = errorMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings & Playback Options")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Scaling Mode
                HStack {
                    Label("Scaling Mode", systemImage: "aspectratio")
                    Spacer()
                    Picker("", selection: $settings.configuration.scalingMode) {
                        ForEach(VideoScalingMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .onChange(of: settings.configuration.scalingMode) { _, newMode in
                        settings.save()
                        DesktopWallpaperController.shared.setScalingMode(newMode)
                    }
                }
                
                Divider()
                
                // Looping toggle
                Toggle(isOn: $settings.configuration.isLooping) {
                    Label("Loop Playback Continuously", systemImage: "repeat")
                }
                .onChange(of: settings.configuration.isLooping) { _, _ in
                    settings.save()
                }
                
                Divider()
                
                // Auto-play on launch
                Toggle(isOn: $settings.configuration.autoPlayOnLaunch) {
                    Label("Auto-start Wallpaper on App Launch", systemImage: "play.circle")
                }
                .onChange(of: settings.configuration.autoPlayOnLaunch) { _, _ in
                    settings.save()
                }
                
                Divider()
                
                // Launch at login
                Toggle(isOn: $settings.configuration.launchAtLogin) {
                    Label("Launch at macOS Login", systemImage: "power")
                }
                .onChange(of: settings.configuration.launchAtLogin) { _, enabled in
                    settings.save()
                    do {
                        try LaunchAtLoginService.setEnabled(enabled)
                    } catch {
                        errorMessage = "Failed to update launch at login: \(error.localizedDescription)"
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            
            // Lock Screen Info Notice
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.shield")
                    .foregroundColor(.secondary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lock Screen Live Wallpaper Support")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("macOS Tahoe 26 does not provide public APIs for arbitrary lock screen video wallpapers. Desktop wallpaper is fully active behind your icons.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
    }
}
