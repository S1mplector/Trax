#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-debug}"
APP_DIR="$ROOT_DIR/build/Trax.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_SOURCE="$ROOT_DIR/Support/Trax/AppIcon.svg"
ICONSET_DIR="$ROOT_DIR/build/Trax.iconset"
ICON_PNG="$ROOT_DIR/build/Trax-icon-1024.png"
ICON_FILE="$RESOURCES_DIR/Trax.icns"

swift build -c "$CONFIGURATION" --package-path "$ROOT_DIR"
BUILD_DIR="$(swift build -c "$CONFIGURATION" --package-path "$ROOT_DIR" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/Trax" "$MACOS_DIR/Trax"
cp "$ROOT_DIR/Support/Trax/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/Trax"

if [[ -f "$ICON_SOURCE" ]]; then
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"
    sips -s format png "$ICON_SOURCE" --out "$ICON_PNG" >/dev/null

    for size in 16 32 128 256 512; do
        sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
        double_size=$((size * 2))
        sips -z "$double_size" "$double_size" "$ICON_PNG" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
    done

    iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"
fi

codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "$APP_DIR"
