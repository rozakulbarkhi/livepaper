import Foundation

public enum WallpaperStatus: Equatable, Sendable {
    case idle
    case loading
    case playing(videoName: String)
    case paused
    case error(message: String)
    
    public var statusDescription: String {
        switch self {
        case .idle:
            return "No wallpaper running"
        case .loading:
            return "Loading video..."
        case .playing(let name):
            return "Active: \(name)"
        case .paused:
            return "Paused"
        case .error(let msg):
            return "Error: \(msg)"
        }
    }
    
    public var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }
}
