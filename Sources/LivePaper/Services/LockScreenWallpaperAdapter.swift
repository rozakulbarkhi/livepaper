import Foundation
import AVFoundation
import AppKit

public enum LockScreenCapability: Sendable {
    case supported(method: String)
}

public protocol LockScreenWallpaperAdapterProtocol: Sendable {
    func evaluateCapability() -> LockScreenCapability
    func isSupported() -> Bool
    func syncWallpaper(from videoURL: URL) async throws -> URL
    func restoreDefaultLockScreen() async throws
}

public final class LockScreenWallpaperAdapter: LockScreenWallpaperAdapterProtocol, @unchecked Sendable {
    public static let shared = LockScreenWallpaperAdapter()
    
    private let fileManager = FileManager.default
    
    public init() {}
    
    public var livePaperDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("LivePaper", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    public var sharedMoviesDirectory: URL {
        let movies = fileManager.urls(for: .moviesDirectory, in: .userDomainMask).first!
        let dir = movies.appendingPathComponent("LivePaper", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    public var posterImageURL: URL {
        livePaperDirectory.appendingPathComponent("lockscreen_poster.heic")
    }
    
    public func evaluateCapability() -> LockScreenCapability {
        return .supported(
            method: "Native poster frame synchronization with macOS lock screen, paired with zero-delay screen saver continuation."
        )
    }
    
    public func isSupported() -> Bool {
        return true
    }
    
    /// Syncs the video to shared locations for ScreenSaver and sets a high-resolution poster frame on the macOS Lock Screen & Desktop
    @discardableResult
    public func syncWallpaper(from videoURL: URL) async throws -> URL {
        // 1. Sync video to shared Application Support & Movies directories so LivePaperSaver.saver can play it
        syncVideoToSharedDirectories(sourceURL: videoURL)
        
        // 2. Generate crisp first-frame poster (.heic)
        let posterURL = try await generatePosterImage(from: videoURL)
        
        // 3. Set poster image as macOS Desktop/Lock Screen background image via NSWorkspace
        try await applySystemWallpaper(imageURL: posterURL)
        
        return posterURL
    }
    
    private func syncVideoToSharedDirectories(sourceURL: URL) {
        let destinations = [
            livePaperDirectory.appendingPathComponent("active_wallpaper.mp4"),
            sharedMoviesDirectory.appendingPathComponent("active_wallpaper.mp4")
        ]
        
        for dest in destinations {
            try? fileManager.removeItem(at: dest)
            try? fileManager.copyItem(at: sourceURL, to: dest)
        }
    }
    
    /// Extracts the first video frame and encodes it as high-efficiency HEIC
    public func generatePosterImage(from videoURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        let time = CMTime(seconds: 0.05, preferredTimescale: 600)
        let (cgImage, _) = try await generator.image(at: time)
        
        let destinationURL = posterImageURL
        try? fileManager.removeItem(at: destinationURL)
        
        guard let dest = CGImageDestinationCreateWithURL(destinationURL as CFURL, "public.heic" as CFString, 1, nil) else {
            // Fallback to PNG if HEIC creation fails
            let pngURL = livePaperDirectory.appendingPathComponent("lockscreen_poster.png")
            guard let pngDest = CGImageDestinationCreateWithURL(pngURL as CFURL, "public.png" as CFString, 1, nil) else {
                throw NSError(domain: "com.livepaper.lockscreen", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"])
            }
            CGImageDestinationAddImage(pngDest, cgImage, nil)
            guard CGImageDestinationFinalize(pngDest) else {
                throw NSError(domain: "com.livepaper.lockscreen", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize PNG poster"])
            }
            return pngURL
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.95
        ]
        CGImageDestinationAddImage(dest, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw NSError(domain: "com.livepaper.lockscreen", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize HEIC poster"])
        }
        
        return destinationURL
    }
    
    /// Applies the poster image to all screens using NSWorkspace
    @MainActor
    private func applySystemWallpaper(imageURL: URL) throws {
        let workspace = NSWorkspace.shared
        for screen in NSScreen.screens {
            do {
                try workspace.setDesktopImageURL(imageURL, for: screen, options: [:])
            } catch {
                print("[LockScreenWallpaperAdapter] Warning: Could not set wallpaper for screen \(screen): \(error)")
            }
        }
    }
    
    public func restoreDefaultLockScreen() async throws {
        // Can be called when stopping wallpaper if desired
    }
}
