#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="Storage Cleaner"
BUNDLE_ID="com.shakir.storageCleanerMac"
VERSION="1.0"
BINARY_NAME="StorageCleanerMac"

APP="$PROJECT_DIR/.build/$BINARY_NAME.app"
BINARY=".build/release/$BINARY_NAME"

# ── Build ─────────────────────────────────────────────────────────────────────
echo "Building $APP_NAME..."
swift build -c release 2>&1

if [ ! -f "$BINARY" ]; then
    echo "Build failed: binary not found."
    exit 1
fi

# ── Assemble .app bundle ──────────────────────────────────────────────────────
MACOS_DIR="$APP/Contents/MacOS"
mkdir -p "$MACOS_DIR"
cp "$BINARY" "$MACOS_DIR/$BINARY_NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>      <string>$BINARY_NAME</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>NSPrincipalClass</key>        <string>NSApplication</string>
</dict>
</plist>
PLIST

# ── Run or Package ────────────────────────────────────────────────────────────
if [ "$1" = "p" ]; then
    DMG="$PROJECT_DIR/.build/$APP_NAME.dmg"
    STAGING="/tmp/${BINARY_NAME}_dmg_staging"

    echo "Creating DMG..."
    rm -rf "$STAGING"
    mkdir -p "$STAGING"
    cp -r "$APP" "$STAGING/"
    ln -sf /Applications "$STAGING/Applications"

    # Remove old DMG if exists
    rm -f "$DMG"

    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$STAGING" \
        -ov \
        -format UDZO \
        -fs HFS+ \
        "$DMG" 2>&1

    rm -rf "$STAGING"

    DMG_SIZE=$(du -sh "$DMG" | cut -f1)
    echo "✓ DMG created: $DMG ($DMG_SIZE)"
    echo "Opening..."
    open "$DMG"
else
    echo "Launching..."
    open "$APP"
fi
