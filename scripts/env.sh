# Shared by the scripts: build without Xcode, outside iCloud Drive.
# The macOS 27 SDK lacks the SwiftUI / Swift Testing macro plugins, so pin 26.5.
# ~/Documents is synced by iCloud, which tags bundles with Finder info that
# codesign rejects, so SwiftPM builds under ~/Library/Caches instead.
export SDKROOT="${KELOQZ_SDK:-/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk}"
KELOQZ_SCRATCH="$HOME/Library/Caches/Keloqz/build"
