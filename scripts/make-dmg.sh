#!/usr/bin/env bash
# Builds Lyric.app and packs it into a drag-and-drop installer: build/Lyric-<version>.dmg
# Needs Python 3; dmgbuild is installed into .build/dmg-venv on first run.
set -euo pipefail
cd "$(dirname "$0")/.."

# Release builds are signed ad-hoc unless SIGN_IDENTITY is set (e.g. a Developer ID).
SIGN_IDENTITY="${SIGN_IDENTITY:--}" ./scripts/build-app.sh

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
DMG="build/Lyric-${VERSION}.dmg"

VENV=".build/dmg-venv"
if [[ ! -x "$VENV/bin/dmgbuild" ]]; then
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install --quiet dmgbuild
fi

# One background file with both 1x and 2x images, so the window is sharp on Retina.
tiffutil -cathidpicheck scripts/dmg/background.png scripts/dmg/background@2x.png -out build/dmg-background.tiff >/dev/null

rm -f "$DMG"
"$VENV/bin/dmgbuild" \
    -s scripts/dmg/settings.py \
    -D app=build/Lyric.app \
    -D background=build/dmg-background.tiff \
    -D volume_icon=Resources/AppIcon.icns \
    "Lyric" "$DMG"

echo "Built $DMG"
