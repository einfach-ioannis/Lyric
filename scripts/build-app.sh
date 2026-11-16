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
# iCloud Drive (File Provider) keeps re-adding extended attributes inside Documents, which
# codesign rejects, so sign a copy in a temporary folder and move it back.
SIGN_DIR="$(mktemp -d)"
trap 'rm -rf "$SIGN_DIR"' EXIT
ditto --norsrc --noextattr "$APP" "$SIGN_DIR/Lyric.app"
if [[ "$IDENTITY" == "-" ]]; then
    codesign --force --sign - --identifier lyric.einfach.de "$SIGN_DIR/Lyric.app"
else
    codesign --force --sign "$IDENTITY" --identifier lyric.einfach.de \
        --options runtime --entitlements Resources/Lyric.entitlements "$SIGN_DIR/Lyric.app"
fi
rm -rf "$APP"
ditto "$SIGN_DIR/Lyric.app" "$APP"
echo "Signed with: $IDENTITY"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x Lyric 2>/dev/null || true
    rm -rf /Applications/Lyric.app
    ditto "$SIGN_DIR/Lyric.app" /Applications/Lyric.app
    echo "Installed to /Applications/Lyric.app"
fi
