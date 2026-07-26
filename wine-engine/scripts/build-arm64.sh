#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ensure_dirs
require_cmd git
require_cmd brew
require_cmd clang
require_cmd make
require_cmd rsync
require_cmd xcrun

TARGET_ARCH="arm64"

clone_or_update_wine_source
setup_arch_runner "$TARGET_ARCH"
build_wine_prefix "$TARGET_ARCH"
make_app_bundle_from_prefix "$TARGET_ARCH"

log "arm64 Wine engine build complete"
