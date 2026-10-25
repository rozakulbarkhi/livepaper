import Foundation

public enum LockScreenCapability: Sendable {
    case unsupported(reason: String)
    case experimentalAvailable(technique: String)
}

public protocol LockScreenWallpaperAdapterProtocol: Sendable {
    func evaluateCapability() -> LockScreenCapability
    func isSupported() -> Bool
    func setLockScreenWallpaper(url: URL) async throws
    func restoreDefaultLockScreen() async throws
}

public final class LockScreenWallpaperAdapter: LockScreenWallpaperAdapterProtocol, @unchecked Sendable {
    public static let shared = LockScreenWallpaperAdapter()
    
    public init() {}
    
    public func evaluateCapability() -> LockScreenCapability {
        return .unsupported(
            reason: "macOS Tahoe 26 does not expose a public API for third-party dynamic lock screen video playback. Modification of idleassetsd or system directories is unsupported and restricted by Apple security policies."
        )
    }
    
    public func isSupported() -> Bool {
        return false
    }
    
    public func setLockScreenWallpaper(url: URL) async throws {
        throw NSError(
            domain: "com.livepaper.lockscreen",
            code: 403,
            userInfo: [
                NSLocalizedDescriptionKey: "Arbitrary video lock screen wallpaper is not supported via public Apple APIs on macOS Tahoe 26. LivePaper strictly protects system integrity and does not modify protected system files."
            ]
        )
    }
    
    public func restoreDefaultLockScreen() async throws {
        // No-op
    }
}
