import Foundation
import AVFoundation

public enum VideoScalingMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case aspectFill = "aspectFill"
    case aspectFit = "aspectFit"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .aspectFill: return "Aspect Fill"
        case .aspectFit: return "Aspect Fit"
        }
    }
    
    public var videoGravity: AVLayerVideoGravity {
        switch self {
        case .aspectFill: return .resizeAspectFill
        case .aspectFit: return .resizeAspect
        }
    }
}

public struct RecentWallpaperItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String { path }
    public let path: String
    public let name: String
    public let bookmark: Data?
    
    public init(path: String, name: String, bookmark: Data?) {
        self.path = path
        self.name = name
        self.bookmark = bookmark
    }
}

public struct WallpaperConfiguration: Codable, Equatable, Sendable {
    public var videoBookmark: Data?
    public var videoPath: String?
    public var videoName: String?
    public var isMuted: Bool
    public var isLooping: Bool
    public var pauseOnBattery: Bool
    public var applyOnLockScreen: Bool
    public var scalingMode: VideoScalingMode
    public var autoPlayOnLaunch: Bool
    public var launchAtLogin: Bool
    public var recentWallpapers: [RecentWallpaperItem]
    
    public init(
        videoBookmark: Data? = nil,
        videoPath: String? = nil,
        videoName: String? = nil,
        isMuted: Bool = true,
        isLooping: Bool = true,
        pauseOnBattery: Bool = false,
        applyOnLockScreen: Bool = true,
        scalingMode: VideoScalingMode = .aspectFill,
        autoPlayOnLaunch: Bool = true,
        launchAtLogin: Bool = false,
        recentWallpapers: [RecentWallpaperItem] = []
    ) {
        self.videoBookmark = videoBookmark
        self.videoPath = videoPath
        self.videoName = videoName
        self.isMuted = isMuted
        self.isLooping = isLooping
        self.pauseOnBattery = pauseOnBattery
        self.applyOnLockScreen = applyOnLockScreen
        self.scalingMode = scalingMode
        self.autoPlayOnLaunch = autoPlayOnLaunch
        self.launchAtLogin = launchAtLogin
        self.recentWallpapers = recentWallpapers
    }
}
