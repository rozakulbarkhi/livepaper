import AppKit

guard let sourceImage = NSImage(contentsOfFile: "Assets/AppIcon_artwork.png") else {
    print("Failed to load Assets/AppIcon_artwork.png")
    exit(1)
}

func resizeAndSave(image: NSImage, dimension: CGFloat, outputPath: String) {
    let newImage = NSImage(size: NSSize(width: dimension, height: dimension))
    newImage.lockFocus()
    
    // Draw with high quality interpolation
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: dimension, height: dimension),
               from: NSRect(origin: .zero, size: image.size),
               operation: .copy,
               fraction: 1.0)
    
    newImage.unlockFocus()
    
    guard let tiff = newImage.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to convert image for \(outputPath)")
        return
    }
    try? png.write(to: URL(fileURLWithPath: outputPath))
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

let fileManager = FileManager.default
try? fileManager.createDirectory(atPath: "Assets/AppIcon.iconset", withIntermediateDirectories: true)

for (name, dimension) in sizes {
    resizeAndSave(image: sourceImage, dimension: dimension, outputPath: "Assets/AppIcon.iconset/\(name)")
}
print("Generated all icon sizes into iconset.")
