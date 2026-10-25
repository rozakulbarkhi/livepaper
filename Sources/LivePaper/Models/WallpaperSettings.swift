import Foundation
import Combine
import SwiftUI

@MainActor
public final class WallpaperSettings: ObservableObject {
    @Published public var configuration: WallpaperConfiguration
    @Published public var status: WallpaperStatus = .idle
    @Published public var activeVideoURL: URL?
    
    private let persistenceService: WallpaperPersistenceServiceProtocol
    
    public init(persistenceService: WallpaperPersistenceServiceProtocol = WallpaperPersistenceService.shared) {
        self.persistenceService = persistenceService
        self.configuration = persistenceService.load()
    }
    
    public func save() {
        persistenceService.save(configuration: configuration)
    }
    
    public func updateVideo(url: URL, bookmark: Data?) {
        configuration.videoPath = url.path
        configuration.videoName = url.lastPathComponent
        configuration.videoBookmark = bookmark
        activeVideoURL = url
        save()
    }
    
    public func clearVideo() {
        configuration.videoPath = nil
        configuration.videoName = nil
        configuration.videoBookmark = nil
        activeVideoURL = nil
        status = .idle
        save()
    }
}
