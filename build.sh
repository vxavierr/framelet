#!/usr/bin/env bash
set -euo pipefail
framelet_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
source_dir="$framelet_dir/native-src"
build_dir="$framelet_dir/.build"
export TMPDIR="$build_dir/tmp"
mkdir -p -- "$TMPDIR"
# No downloads or system changes. CMake reports any missing development library.
cmake -S "$source_dir" -B "$build_dir" -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF "${@}"
cmake --build "$build_dir" --target omaframe -j 3
mkdir -p -- "$framelet_dir/native"
install -m755 "$build_dir/framelet" "$framelet_dir/native/capture-engine"
# The launcher rebuilds when this stamp differs from the plugin version, so an
# update through `omarchy plugin update` also updates the engine.
sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$framelet_dir/manifest.json" | head -n 1 > "$framelet_dir/native/version"
rm -f -- "$framelet_dir/native/failed-version"
printf '%s\n' 'Framelet: engine built.'
