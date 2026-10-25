import XCTest
@testable import LivePaper

final class LivePaperTests: XCTestCase {
    func testConfigurationDefaults() {
        let config = WallpaperConfiguration()
        XCTAssertTrue(config.isMuted)
        XCTAssertTrue(config.isLooping)
        XCTAssertTrue(config.autoPlayOnLaunch)
        XCTAssertFalse(config.launchAtLogin)
        XCTAssertEqual(config.scalingMode, .aspectFill)
        XCTAssertNil(config.videoPath)
        XCTAssertNil(config.videoName)
    }
    
    func testScalingModes() {
        XCTAssertEqual(VideoScalingMode.aspectFill.videoGravity, .resizeAspectFill)
        XCTAssertEqual(VideoScalingMode.aspectFit.videoGravity, .resizeAspect)
        XCTAssertEqual(VideoScalingMode.aspectFill.displayName, "Aspect Fill")
        XCTAssertEqual(VideoScalingMode.aspectFit.displayName, "Aspect Fit")
    }
    
    func testConfigurationSerialization() throws {
        var config = WallpaperConfiguration()
        config.videoPath = "/Users/test/video.mp4"
        config.videoName = "video.mp4"
        config.scalingMode = .aspectFit
        config.isLooping = false
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WallpaperConfiguration.self, from: data)
        
        XCTAssertEqual(config, decoded)
        XCTAssertEqual(decoded.videoName, "video.mp4")
        XCTAssertEqual(decoded.scalingMode, .aspectFit)
        XCTAssertFalse(decoded.isLooping)
    }
    
    func testLockScreenCapabilityReport() {
        let adapter = LockScreenWallpaperAdapter()
        let capability = adapter.evaluateCapability()
        XCTAssertFalse(adapter.isSupported())
        
        if case .unsupported(let reason) = capability {
            XCTAssertTrue(reason.contains("macOS"))
        } else {
            XCTFail("Lock screen should be reported as unsupported via public APIs")
        }
    }
}
