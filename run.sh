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
ICNS=".build/AppIcon.icns"

# ── Icon ──────────────────────────────────────────────────────────────────────
build_icon() {
    echo "Generating icon..."
    mkdir -p .build
    swift Scripts/make_icon.swift .build/icon_1024.png

    ICONSET=".build/AppIcon.iconset"
    rm -rf "$ICONSET" && mkdir "$ICONSET"

    declare -a SIZES=(16 32 64 128 256 512 1024)
    declare -a NAMES=(
        "icon_16x16"
        "icon_16x16@2x"   # 32
        "icon_32x32"       # 64 → named as 32@2x
        "icon_32x32@2x"   # 64
        "icon_128x128"
        "icon_128x128@2x"
        "icon_256x256"
        "icon_256x256@2x"
        "icon_512x512"
        "icon_512x512@2x"
    )
    declare -a PIXELS=(16 32 32 64 128 256 256 512 512 1024)

    for i in "${!NAMES[@]}"; do
        sips -z "${PIXELS[$i]}" "${PIXELS[$i]}" .build/icon_1024.png \
             --out "$ICONSET/${NAMES[$i]}.png" > /dev/null 2>&1
    done

    iconutil -c icns "$ICONSET" -o "$ICNS"
    rm -rf "$ICONSET" .build/icon_1024.png
    echo "Icon ready → $ICNS"
}

[ ! -f "$ICNS" ] && build_icon

# ── Build ─────────────────────────────────────────────────────────────────────
echo "Building $APP_NAME..."
swift build -c release 2>&1

if [ ! -f "$BINARY" ]; then
    echo "Build failed: binary not found."
    exit 1
fi

# ── Assemble .app bundle ──────────────────────────────────────────────────────
MACOS_DIR="$APP/Contents/MacOS"
RES_DIR="$APP/Contents/Resources"
mkdir -p "$MACOS_DIR" "$RES_DIR"
cp "$BINARY" "$MACOS_DIR/$BINARY_NAME"
cp "$ICNS"   "$RES_DIR/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>        <string>$BINARY_NAME</string>
    <key>CFBundleIdentifier</key>        <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>              <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>       <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>          <string>AppIcon</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>    <string>13.0</string>
    <key>NSHighResolutionCapable</key>   <true/>
    <key>NSPrincipalClass</key>          <string>NSApplication</string>
</dict>
</plist>
PLIST

# ── Run or Package ────────────────────────────────────────────────────────────
if [ "$1" = "p" ]; then
    DMG="$PROJECT_DIR/.build/$APP_NAME.dmg"
    STAGING="/tmp/${BINARY_NAME}_dmg_staging"

    echo "Creating DMG..."
    rm -rf "$STAGING" && mkdir -p "$STAGING"
    cp -r "$APP" "$STAGING/"
    ln -sf /Applications "$STAGING/Applications"
    rm -f "$DMG"

    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$STAGING" \
        -ov -format UDZO -fs HFS+ \
        "$DMG" 2>&1

    rm -rf "$STAGING"
    echo "✓ DMG → $DMG ($(du -sh "$DMG" | cut -f1))"
    open "$DMG"
else
    echo "Launching..."
    open "$APP"
fi
