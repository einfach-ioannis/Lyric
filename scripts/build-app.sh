#!/usr/bin/env bash
# Builds Lyric.app into ./build. Pass --install to copy it to /Applications.
set -euo pipefail
cd "$(dirname "$0")/.."

# Universal binary: Apple silicon and the Intel Macs that run macOS 26.
ARCHS=(--arch arm64 --arch x86_64)
CONFIGURATION="${CONFIGURATION:-release}"
swift build -c "$CONFIGURATION" "${ARCHS[@]}"
BIN_DIR="$(swift build -c "$CONFIGURATION" "${ARCHS[@]}" --show-bin-path)"

APP="build/Lyric.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Lyric" "$APP/Contents/MacOS/Lyric"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp -R Resources/*.lproj "$APP/Contents/Resources/"

# Local builds sign with your development identity when one exists, so macOS keeps the
# Automation permission across rebuilds. Override with SIGN_IDENTITY="…", or
# SIGN_IDENTITY=- for ad-hoc (what scripts/make-dmg.sh uses for public releases).
IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Apple Development|Developer ID Application/ {print $2; exit}')}"
IDENTITY="${IDENTITY:--}"
if [[ "$IDENTITY" == "-" ]]; then
    codesign --force --sign - --identifier lyric.einfach.de "$APP"
else
    codesign --force --sign "$IDENTITY" --identifier lyric.einfach.de \
        --options runtime --entitlements Resources/Lyric.entitlements "$APP"
fi
echo "Signed with: $IDENTITY"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x Lyric 2>/dev/null || true
    rm -rf /Applications/Lyric.app
    cp -R "$APP" /Applications/
    echo "Installed to /Applications/Lyric.app"
fi
