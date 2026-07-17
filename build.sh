#!/bin/bash
# Builds dist/Herdr.app from src/ and assets/.
# Pass --install to also copy the result to /Applications.
# Uses only tools that ship with macOS: sips, iconutil, codesign.

set -euo pipefail
cd "$(dirname "$0")"

APP="dist/Herdr.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Icon: assets/icon-1024.png -> Herdr.icns
ICONSET_DIR="$(mktemp -d)"
ICONSET="$ICONSET_DIR/Herdr.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  retina=$((size * 2))
  sips -z "$size" "$size" assets/icon-1024.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  sips -z "$retina" "$retina" assets/icon-1024.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Herdr.icns"
rm -rf "$ICONSET_DIR"

cp src/Info.plist "$APP/Contents/Info.plist"
install -m 755 src/launcher.sh "$APP/Contents/MacOS/herdr-launcher"

# Ad-hoc signature gives the app a stable identity, so the Automation
# permission you grant on first run survives rebuilds. A signing or
# verification failure fails the build.
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"

echo "Built $APP"

if [ "${1:-}" = "--install" ]; then
  rm -rf /Applications/Herdr.app
  ditto "$APP" /Applications/Herdr.app
  echo "Installed /Applications/Herdr.app"
fi
