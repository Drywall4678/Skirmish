#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log "Checking tools"
require_cmd brew
require_cmd git
require_cmd curl
require_cmd tar
require_cmd unzip

log "Installing build dependencies with Homebrew"
brew update

brew install \
  autoconf \
  automake \
  bison \
  flex \
  freetype \
  gettext \
  gnutls \
  libpng \
  libtiff \
  libtool \
  mingw-w64 \
  pkg-config \
  sdl2 \
  xz \
  yajl

log "Bootstrap complete"
