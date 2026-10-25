import Foundation
import AVFoundation

public enum VideoScalingMode: String, Codable, CaseIterable, Identifiable {
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

public struct WallpaperConfiguration: Codable, Equatable {
    public var videoBookmark: Data?
    public var videoPath: String?
    public var videoName: String?
    public var isMuted: Bool
    public var isLooping: Bool
    public var scalingMode: VideoScalingMode
    public var autoPlayOnLaunch: Bool
    public var launchAtLogin: Bool
    
    public init(
        videoBookmark: Data? = nil,
        videoPath: String? = nil,
        videoName: String? = nil,
        isMuted: Bool = true,
        isLooping: Bool = true,
        scalingMode: VideoScalingMode = .aspectFill,
        autoPlayOnLaunch: Bool = true,
        launchAtLogin: Bool = false
    ) {
        self.videoBookmark = videoBookmark
        self.videoPath = videoPath
        self.videoName = videoName
        self.isMuted = isMuted
        self.isLooping = isLooping
        self.scalingMode = scalingMode
        self.autoPlayOnLaunch = autoPlayOnLaunch
        self.launchAtLogin = launchAtLogin
    }
}
