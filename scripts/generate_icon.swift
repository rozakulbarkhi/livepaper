import AppKit

func generateIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    
    let ctx = NSGraphicsContext.current?.cgContext
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.224 // macOS squircle ratio
    
    // Background squircle with rich purple/blue live-wallpaper gradient
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    path.addClip()
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let startColor = CGColor(red: 0.12, green: 0.14, blue: 0.28, alpha: 1.0)
    let endColor = CGColor(red: 0.38, green: 0.20, blue: 0.65, alpha: 1.0)
    let accentColor = CGColor(red: 0.20, green: 0.60, blue: 0.95, alpha: 1.0)
    
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: [startColor, endColor, accentColor] as CFArray, locations: [0.0, 0.6, 1.0]) {
        ctx?.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    }
    
    // Draw an elegant display frame (representing Desktop Wallpaper)
    let screenPadding = size * 0.20
    let screenRect = NSRect(
        x: screenPadding,
        y: screenPadding * 1.25,
        width: size - screenPadding * 2,
        height: size * 0.52
    )
    let screenPath = NSBezierPath(roundedRect: screenRect, xRadius: size * 0.05, yRadius: size * 0.05)
    NSColor(white: 1.0, alpha: 0.18).setFill()
    screenPath.fill()
    NSColor(white: 1.0, alpha: 0.35).setStroke()
    screenPath.lineWidth = max(1.0, size * 0.02)
    screenPath.stroke()
    
    // Play / Sparkle symbol inside the screen
    let trianglePath = NSBezierPath()
    let centerX = screenRect.midX
    let centerY = screenRect.midY
    let triSize = size * 0.14
    
    trianglePath.move(to: NSPoint(x: centerX - triSize * 0.6, y: centerY - triSize * 0.7))
    trianglePath.line(to: NSPoint(x: centerX + triSize * 0.8, y: centerY))
    trianglePath.line(to: NSPoint(x: centerX - triSize * 0.6, y: centerY + triSize * 0.7))
    trianglePath.close()
    
    NSColor.white.setFill()
    trianglePath.fill()
    
    // Monitor stand
    let standRect = NSRect(x: centerX - size * 0.05, y: screenPadding * 0.85, width: size * 0.10, height: screenPadding * 0.40)
    NSColor(white: 1.0, alpha: 0.4).setFill()
    standRect.fill()
    
    let baseRect = NSRect(x: centerX - size * 0.15, y: screenPadding * 0.70, width: size * 0.30, height: size * 0.03)
    let basePath = NSBezierPath(roundedRect: baseRect, xRadius: size * 0.015, yRadius: size * 0.015)
    basePath.fill()
    
    img.unlockFocus()
    return img
}

func savePNG(image: NSImage, path: String) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        return
    }
    try? png.write(to: URL(fileURLWithPath: path))
}

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, dimension) in sizes {
    let icon = generateIcon(size: dimension)
    savePNG(image: icon, path: "Assets/AppIcon.iconset/\(name)")
}
print("Generated all icon sizes.")
