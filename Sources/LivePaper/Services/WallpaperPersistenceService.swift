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
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func load() -> WallpaperConfiguration {
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
            userDefaults.set(data, forKey: configKey)
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
