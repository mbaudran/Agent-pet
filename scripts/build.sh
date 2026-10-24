#!/bin/bash
# Builds Keloqz.app without Xcode (Command Line Tools only).
#
#   scripts/build.sh            # builds ~/Library/Caches/Keloqz/Keloqz.app
#   scripts/build.sh --install  # also replaces /Applications/Keloqz.app and opens it
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
source scripts/env.sh
APP="$HOME/Library/Caches/Keloqz/Keloqz.app"

SPRITES="Sources/Keloqz/Resources/sprites"
for file in idle.png play.png done.png sleep.png sprites.json; do
    [ -f "$SPRITES/$file" ] || { echo "Missing $SPRITES/$file — run: node tools/render-sprites.mjs" >&2; exit 1; }
done

echo "▸ Compiling…"
swift build -c release --scratch-path "$KELOQZ_SCRATCH"
BIN="$(swift build -c release --scratch-path "$KELOQZ_SCRATCH" --show-bin-path)"

echo "▸ Assembling Keloqz.app…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/Keloqz" "$APP/Contents/MacOS/Keloqz"
cp scripts/Info.plist "$APP/Contents/Info.plist"
cp -R "$BIN/Keloqz_Keloqz.bundle" "$APP/Contents/Resources/"
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
echo "✓ $APP"

if [ "${1:-}" = "--install" ]; then
    echo "▸ Installing in /Applications…"
    osascript -e 'tell application id "com.mba.keloqz" to quit' >/dev/null 2>&1 || true
    pkill -x Keloqz 2>/dev/null || true
    sleep 1
    rm -rf /Applications/Keloqz.app
    cp -R "$APP" /Applications/Keloqz.app
    open /Applications/Keloqz.app
    echo "✓ /Applications/Keloqz.app"
fi
