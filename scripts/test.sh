#!/bin/bash
# Runs the Swift and Node test suites.   scripts/test.sh [--filter <pattern>]
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
# SwiftPM finds Swift Testing's macro plugin on a clean build but loses it on
# incremental ones with the Command Line Tools; load it explicitly.
PLUGIN=/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib
swift test --scratch-path "$KELOQZ_SCRATCH" -Xswiftc -load-plugin-library -Xswiftc "$PLUGIN" "$@"
if [ "$#" -eq 0 ]; then node --test 'tools/*.test.mjs'; fi
