import SwiftUI
import UniformTypeIdentifiers

public struct VideoPickerView: View {
    @ObservedObject var settings: WallpaperSettings
    @Binding var errorMessage: String?
    @State private var isShowingPicker = false
    
    public init(settings: WallpaperSettings, errorMessage: Binding<String?>) {
        self.settings = settings
        self._errorMessage = errorMessage
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected Video:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(settings.configuration.videoName ?? "None (Choose an MP4 or MOV file)")
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Button(action: selectFile) {
                Label("Choose Video…", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    private func selectFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Video for Live Wallpaper"
        openPanel.allowedContentTypes = [UTType.mpeg4Movie, UTType.quickTimeMovie, UTType.movie]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        
        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            handleSelectedURL(selectedURL)
        }
    }
    
    private func handleSelectedURL(_ url: URL) {
        let persistence = WallpaperPersistenceService.shared
        let bookmark = persistence.createBookmark(for: url)
        settings.updateVideo(url: url, bookmark: bookmark)
        errorMessage = nil
    }
}
