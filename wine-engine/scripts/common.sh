#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
WINE_SRC_DIR="$BUILD_DIR/wine-src"
WINE_REPO_URL="${WINE_REPO_URL:-https://gitlab.winehq.org/wine/wine.git}"
WINE_REF="${WINE_REF:-}"

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

clone_or_update_wine_source() {
  if [ ! -d "$WINE_SRC_DIR/.git" ]; then
    log "Cloning Wine source"
    git clone --depth 1 "$WINE_REPO_URL" "$WINE_SRC_DIR"
  fi

  if [ -n "$WINE_REF" ]; then
    log "Checking out Wine ref: $WINE_REF"
    git -C "$WINE_SRC_DIR" fetch --depth 1 origin "$WINE_REF"
    git -C "$WINE_SRC_DIR" checkout FETCH_HEAD
  fi
}

host_sdkroot() {
  xcrun --sdk macosx --show-sdk-path
}

brew_pkg_config_path() {
  local formulas=(freetype gettext gnutls libpng libtiff sdl2 xz yajl)
  local paths=()
  local prefix

  for formula in "${formulas[@]}"; do
    if prefix="$(brew --prefix "$formula" 2>/dev/null)"; then
      [ -d "$prefix/lib/pkgconfig" ] && paths+=("$prefix/lib/pkgconfig")
      [ -d "$prefix/share/pkgconfig" ] && paths+=("$prefix/share/pkgconfig")
    fi
  done

  (IFS=:; echo "${paths[*]-}")
}

setup_arch_runner() {
  local target_arch="$1"
  ARCH_RUNNER=()

  if [ "$target_arch" = "x86_64" ] && [ "$(uname -m)" = "arm64" ]; then
    ARCH_RUNNER=(arch -x86_64)
  fi
}

run_target() {
  "${ARCH_RUNNER[@]}" "$@"
}

build_wine_prefix() {
  local target_arch="$1"
  local build_root="$BUILD_DIR/$target_arch"
  local build_dir="$build_root/build"
  local prefix_dir="$build_root/prefix"
  local sdkroot
  local pkgconfig_path

  sdkroot="$(host_sdkroot)"
  pkgconfig_path="$(brew_pkg_config_path)"

  rm -rf "$build_dir"
  mkdir -p "$build_dir" "$prefix_dir"

  pushd "$build_dir" >/dev/null

  log "Configuring Wine for $target_arch"
  run_target env \
    SDKROOT="$sdkroot" \
    CC=clang \
    CXX=clang++ \
    CFLAGS="-O2 -arch $target_arch -isysroot $sdkroot" \
    CXXFLAGS="-O2 -arch $target_arch -isysroot $sdkroot" \
    CPPFLAGS="-isysroot $sdkroot" \
    LDFLAGS="-arch $target_arch -isysroot $sdkroot" \
    PKG_CONFIG_PATH="$pkgconfig_path" \
    "$WINE_SRC_DIR/configure" \
      --prefix="$prefix_dir" \
      --disable-tests

  log "Building Wine for $target_arch"
  run_target make -j"$(sysctl -n hw.ncpu)"

  log "Installing Wine for $target_arch"
  run_target make install

  popd >/dev/null
}

make_app_bundle_from_prefix() {
  local target_arch="$1"
  local build_root="$BUILD_DIR/$target_arch"
  local prefix_dir="$build_root/prefix"
  local bundle_dir="$build_root/Wine.app"
  local macos_dir="$bundle_dir/Contents/MacOS"
  local resources_dir="$bundle_dir/Contents/Resources"

  rm -rf "$bundle_dir"
  mkdir -p "$macos_dir" "$resources_dir"

  cat > "$bundle_dir/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>wine</string>
  <key>CFBundleIdentifier</key>
  <string>com.example.wineengine</string>
  <key>CFBundleName</key>
  <string>Wine</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
</dict>
</plist>
EOF

  log "Copying installed prefix into app bundle"
  rsync -a "$prefix_dir/" "$resources_dir/prefix/"

  cat > "$macos_dir/wine" <<'EOF'
#!/bin/bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PREFIX="$HERE/../Resources/prefix"

export WINEPREFIX="${WINEPREFIX:-$HOME/Library/Application Support/WineEngine/prefix}"
exec "$PREFIX/bin/wine" "$@"
EOF
  chmod +x "$macos_dir/wine"

  log "Created bundle: $bundle_dir"
}
