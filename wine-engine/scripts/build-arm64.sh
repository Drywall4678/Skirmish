#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ensure_dirs
require_cmd clang
require_cmd make
require_cmd pkg-config

ARCH="arm64"
OUT_DIR="$BUILD_DIR/$ARCH"
SRC_DIR="$BUILD_DIR/src"
PREFIX="$OUT_DIR/prefix"

mkdir -p "$OUT_DIR" "$SRC_DIR" "$PREFIX"

log "Building Wine engine for $ARCH"
log "Output directory: $OUT_DIR"

# Replace this section with your real Wine source build steps.
# Typical flow:
#   1. fetch Wine source
#   2. configure with the correct arch flags
#   3. build
#   4. install into PREFIX
#
# Example scaffold:
# cd "$SRC_DIR/wine-source"
# export CC=clang
# export CFLAGS="-arch arm64"
# export LDFLAGS="-arch arm64"
# ./configure --prefix="$PREFIX"
# make -j"$(sysctl -n hw.ncpu)"
# make install

make_bundle_layout "$OUT_DIR"
touch "$OUT_DIR/Wine.app/Contents/MacOS/wine"
chmod +x "$OUT_DIR/Wine.app/Contents/MacOS/wine"

log "arm64 build scaffold complete"
