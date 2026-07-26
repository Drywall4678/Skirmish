#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

die() {
  echo "Error: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

ensure_dirs() {
  mkdir -p "$BUILD_DIR" "$DIST_DIR"
}

host_arch() {
  uname -m
}

make_bundle_layout() {
  local target_dir="$1"
  mkdir -p "$target_dir/Wine.app/Contents/MacOS"
  mkdir -p "$target_dir/Wine.app/Contents/Resources"
}
