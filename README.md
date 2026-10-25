# LivePaper — Native macOS Live Wallpaper

A native, lightweight macOS application built with Swift, SwiftUI, AppKit, and AVFoundation that turns any MP4 or MOV video file into an animated desktop wallpaper.

Targeted for **macOS 14.0+ through macOS Tahoe 26.0+**, designed for personal use with zero paid dependencies and minimal battery and CPU footprint.

---

## Architecture & Features

### 1. Desktop Live Wallpaper (Primary Goal)
- **Native Video Engine**: Uses `AVQueuePlayer` and `AVPlayerLooper` for seamless, gapless looping. Audio is explicitly muted (`player.isMuted = true`) to prevent unwanted sound.
- **Desktop Level Rendering**: AppKit borderless windows positioned at `CGWindowLevelForKey(.desktopWindow)`. 
  - Allows full Finder icon visibility and interaction.
  - Windows ignore mouse events (`ignoresMouseEvents = true`) so clicking desktop items passes straight through to Finder.
  - Pinned with `.canJoinAllSpaces` and `.stationary` collection behaviors so spaces, Mission Control, and full-screen transitions operate smoothly.
- **Multi-Monitor Display Management**: Listens to `NSApplication.didChangeScreenParametersNotification` via `DisplayMonitorService` to automatically recreate/adjust wallpaper windows when displays are connected, disconnected, or have resolution changes.
- **Power & Thermal Optimization**: Automatically pauses playback upon system sleep (`NSWorkspace.willSleepNotification`) or screen sleep (`NSWorkspace.screensDidSleepNotification`), and resumes immediately on wake to save battery and prevent GPU churn.
- **Security-Scoped Bookmarks**: Retains access to user-selected video files across application restarts without requiring sandbox bypass or root privileges.
- **Configurable Video Scaling**: Supports both **Aspect Fill** (`.resizeAspectFill`) and **Aspect Fit** (`.resizeAspect`).
- **Launch at Login**: Integrates native macOS `SMAppService.mainApp` for clean login startup.

### 2. Lock Screen Live Wallpaper (Investigation & Feasibility)
- **Public API Status on macOS Tahoe 26**:
  - Apple does **not** provide any public developer API to render arbitrary video streams directly onto the native macOS lock screen prior to screen-saver activation.
  - System dynamic aerial wallpapers and lock screen transitions are managed internally by private system daemons (`idleassetsd`, `com.apple.wallpaper`, and `ScreenSaverEngine`).
  - System locations (`/System/Library/Desktop Pictures/` and asset caches) are protected by **System Integrity Protection (SIP)**.
- **Safety Policy**:
  - `LivePaper` adheres strictly to standard Apple security guidelines. It **does not** require root, does **not** disable SIP, and does **not** tamper with or overwrite system files.
  - An isolated `LockScreenWallpaperAdapter` protocol is provided in the codebase to report capability status and maintain a clear separation of concerns.

---

## Project Structure

```
LivePaper/
├── Package.swift                             # Swift Package Manager manifest
├── Sources/
│   └── LivePaper/
│       ├── App/
│       │   └── LivePaperApp.swift            # SwiftUI App entry point & lifecycle
│       ├── Models/
│       │   ├── WallpaperConfiguration.swift  # Codable configuration model
│       │   ├── WallpaperSettings.swift       # Observable settings state manager
│       │   └── WallpaperStatus.swift         # Wallpaper engine states (idle/loading/playing/error)
│       ├── Services/
│       │   ├── DesktopWallpaperController.swift  # Desktop window & player manager
│       │   ├── DesktopWallpaperWindow.swift      # AppKit window positioned at desktop level
│       │   ├── WallpaperPlayer.swift             # AVFoundation AVQueuePlayer + Looper
│       │   ├── WallpaperPersistenceService.swift # Security-scoped bookmark & UserDefaults persistence
│       │   ├── DisplayMonitorService.swift       # Multi-monitor & sleep/wake notifications
│       │   ├── LaunchAtLoginService.swift        # SMAppService integration
│       │   └── LockScreenWallpaperAdapter.swift  # Lock screen API evaluation & isolation
│       └── Views/
│           ├── ContentView.swift             # Main control dashboard
│           ├── VideoPickerView.swift         # Native NSOpenPanel file picker
│           ├── WallpaperPreviewView.swift    # AVKit preview player
│           └── SettingsView.swift            # Scaling, loop, and auto-play controls
└── Tests/
    └── LivePaperTests/
        └── LivePaperTests.swift              # Unit tests for models, serialization, and capabilities
```

---

## Build and Run

### Prerequisites
- macOS 14.0 or macOS Tahoe 26.0+
- Xcode 15+ / Xcode 26+ with Swift 6 support

### Quick Build with Swift CLI
```bash
# Build executable
swift build

# Run unit tests
swift test
```

### Build with Xcode / xcodebuild
You can open the directory directly in Xcode:
```bash
xed .
```
Or build from the terminal using `xcodebuild`:
```bash
xcodebuild -scheme LivePaper -destination "platform=macOS" build
```

---

## Verification & Test Results
- **Unit Tests**:
  - `testConfigurationDefaults`: Verified default mute, loop, autoPlay, and scaling mode.
  - `testConfigurationSerialization`: Verified JSON roundtrip encoding and decoding.
  - `testLockScreenCapabilityReport`: Verified adapter capability inspection and isolation.
  - `testScalingModes`: Verified correct mapping to `AVLayerVideoGravity`.
  - **Result**: `Executed 4 tests, with 0 failures (0 unexpected)`.
- **Xcode Build**:
  - `xcodebuild -scheme LivePaper -destination platform=macOS build` completed with `** BUILD SUCCEEDED **`.
