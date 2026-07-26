#!/bin/bash
set -euo pipefail

mkdir -p dist

if [ -d "build/arm64/Wine.app" ]; then
  cd build/arm64
  zip -r ../../dist/wine-macos-arm64.zip Wine.app
  cd ../..
fi

if [ -d "build/x86_64/Wine.app" ]; then
  cd build/x86_64
  zip -r ../../dist/wine-macos-x86_64.zip Wine.app
  cd ../..
fi

echo "Release archives created in dist/"
