#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-release}"
APP_NAME="Trax"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"
STAGING_DIR="$ROOT_DIR/build/dmg-staging"
DMG_PATH="$ROOT_DIR/build/$APP_NAME.dmg"
DESKTOP_DMG_PATH="$HOME/Desktop/$APP_NAME.dmg"

"$ROOT_DIR/Scripts/package_app.sh" "$CONFIGURATION" >/dev/null

rm -rf "$STAGING_DIR"
rm -f "$DMG_PATH" "$DESKTOP_DMG_PATH"
mkdir -p "$STAGING_DIR"

ditto "$APP_DIR" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

cp "$DMG_PATH" "$DESKTOP_DMG_PATH"

echo "$DESKTOP_DMG_PATH"
