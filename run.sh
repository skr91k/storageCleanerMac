#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "Building StorageCleanerMac..."
swift build -c release 2>&1

BINARY=".build/release/StorageCleanerMac"

if [ ! -f "$BINARY" ]; then
    echo "Build failed: binary not found at $BINARY"
    exit 1
fi

# Assemble a minimal .app bundle so macOS shows the window
APP="$PROJECT_DIR/.build/StorageCleanerMac.app"
MACOS_DIR="$APP/Contents/MacOS"
mkdir -p "$MACOS_DIR"
cp "$BINARY" "$MACOS_DIR/StorageCleanerMac"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>StorageCleanerMac</string>
    <key>CFBundleIdentifier</key>
    <string>com.shakir.storageCleanerMac</string>
    <key>CFBundleName</key>
    <string>Storage Cleaner</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Launching..."
open "$APP"
