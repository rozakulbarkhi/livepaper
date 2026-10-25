#!/bin/bash
set -e

SAVER_NAME="LivePaper"
BUNDLE="${SAVER_NAME}.saver"
CONTENTS="${BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

echo "🔨 Compiling ${SAVER_NAME}.saver..."

rm -rf "${BUNDLE}"
mkdir -p "${MACOS}"
mkdir -p "${RESOURCES}"

# Compile Swift code into dynamic library
swiftc -O \
    -emit-library \
    -module-name LivePaperSaver \
    -target arm64-apple-macos14.0 \
    -framework ScreenSaver \
    -framework AVFoundation \
    -framework AppKit \
    -o "${MACOS}/${SAVER_NAME}" \
    ScreenSaver/LivePaperSaver/LivePaperSaverView.swift

# Create Info.plist
cat <<EOF > "${CONTENTS}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${SAVER_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.livepaper.saver</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${SAVER_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSPrincipalClass</key>
    <string>LivePaperSaverView</string>
</dict>
</plist>
EOF

echo "🔏 Code signing ${BUNDLE}..."
codesign --force --deep --sign - "${BUNDLE}"

echo "✅ Successfully built ${BUNDLE}"
