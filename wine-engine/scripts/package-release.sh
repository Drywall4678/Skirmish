#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ensure_dirs

ARM_BUNDLE="$BUILD_DIR/arm64/Wine.app"
INTEL_BUNDLE="$BUILD_DIR/x86_64/Wine.app"

log "Packaging release archives"

if [ -d "$ARM_BUNDLE" ]; then
  rm -f "$DIST_DIR/wine-macos-arm64.zip"
  (cd "$BUILD_DIR/arm64" && zip -r "$DIST_DIR/wine-macos-arm64.zip" Wine.app)
  log "Created $DIST_DIR/wine-macos-arm64.zip"
else
  log "Skipping arm64 package; bundle not found"
fi

if [ -d "$INTEL_BUNDLE" ]; then
  rm -f "$DIST_DIR/wine-macos-x86_64.zip"
  (cd "$BUILD_DIR/x86_64" && zip -r "$DIST_DIR/wine-macos-x86_64.zip" Wine.app)
  log "Created $DIST_DIR/wine-macos-x86_64.zip"
else
  log "Skipping x86_64 package; bundle not found"
fi
