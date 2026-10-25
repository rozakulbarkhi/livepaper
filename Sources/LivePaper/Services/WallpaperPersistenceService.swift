import Foundation

public protocol WallpaperPersistenceServiceProtocol: Sendable {
    func load() -> WallpaperConfiguration
    func save(configuration: WallpaperConfiguration)
    func createBookmark(for url: URL) -> Data?
    func resolveBookmark(data: Data) -> (url: URL?, isStale: Bool)
}

public final class WallpaperPersistenceService: WallpaperPersistenceServiceProtocol, @unchecked Sendable {
    public static let shared = WallpaperPersistenceService()
    
    private let userDefaults: UserDefaults
    private let configKey = "com.livepaper.configuration"
    
    private var sharedConfigFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("LivePaper", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func load() -> WallpaperConfiguration {
        // First try shared config file (readable by legacyScreenSaver)
        if let fileData = try? Data(contentsOf: sharedConfigFileURL) {
            if let config = try? JSONDecoder().decode(WallpaperConfiguration.self, from: fileData) {
                return config
            }
        }
        
        // Fallback to UserDefaults
        guard let data = userDefaults.data(forKey: configKey) else {
            return WallpaperConfiguration()
        }
        do {
            return try JSONDecoder().decode(WallpaperConfiguration.self, from: data)
        } catch {
            print("[WallpaperPersistenceService] Failed to decode configuration: \(error)")
            return WallpaperConfiguration()
        }
    }
    
    public func save(configuration: WallpaperConfiguration) {
        do {
            let data = try JSONEncoder().encode(configuration)
            // Save to UserDefaults
            userDefaults.set(data, forKey: configKey)
            
            // Also write to shared config file in Application Support for LivePaper.saver
            try? data.write(to: sharedConfigFileURL, options: .atomic)
            
            // Also write to ~/Movies/LivePaper (accessible by legacyScreenSaver sandbox)
            let moviesURL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
            if let moviesDir = moviesURL?.appendingPathComponent("LivePaper", isDirectory: true) {
                try? FileManager.default.createDirectory(at: moviesDir, withIntermediateDirectories: true)
                let moviesConfigFile = moviesDir.appendingPathComponent("config.json")
                try? data.write(to: moviesConfigFile, options: .atomic)
                
                if let path = configuration.videoPath, FileManager.default.fileExists(atPath: path) {
                    let moviesVideoPath = moviesDir.appendingPathComponent("active_wallpaper.mp4")
                    try? FileManager.default.removeItem(at: moviesVideoPath)
                    try? FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: moviesVideoPath)
                }
            }
            
            // Also write active video copy in Application Support/LivePaper/active_wallpaper.mp4
            if let path = configuration.videoPath, FileManager.default.fileExists(atPath: path) {
                let activeVideoPath = sharedConfigFileURL.deletingLastPathComponent().appendingPathComponent("active_wallpaper.mp4")
                try? FileManager.default.removeItem(at: activeVideoPath)
                try? FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: activeVideoPath)
                
                // Also copy directly into installed LivePaper.saver bundle resources if it exists
                let saverResourceDir = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Library/Screen Savers/LivePaper.saver/Contents/Resources", isDirectory: true)
                if FileManager.default.fileExists(atPath: saverResourceDir.path) {
                    let saverVideoPath = saverResourceDir.appendingPathComponent("active_wallpaper.mp4")
                    try? FileManager.default.removeItem(at: saverVideoPath)
                    try? FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: saverVideoPath)
                }
            }
        } catch {
            print("[WallpaperPersistenceService] Failed to encode configuration: \(error)")
        }
    }
    
    public func createBookmark(for url: URL) -> Data? {
        do {
            #if os(macOS)
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            return bookmark
            #else
            return nil
            #endif
        } catch {
            print("[WallpaperPersistenceService] Failed to create bookmark for \(url): \(error)")
            return nil
        }
    }
    
    public func resolveBookmark(data: Data) -> (url: URL?, isStale: Bool) {
        #if os(macOS)
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return (url, isStale)
        } catch {
            print("[WallpaperPersistenceService] Failed to resolve bookmark: \(error)")
            return (nil, false)
        }
        #else
        return (nil, false)
        #endif
    }
}
