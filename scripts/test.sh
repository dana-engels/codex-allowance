#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="${BUILD_DIR:-$root/.build}"
mkdir -p "$build_dir/module-cache"
export CLANG_MODULE_CACHE_PATH="$build_dir/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$build_dir/module-cache"
swift test --package-path "$root" --scratch-path "$build_dir" --cache-path "$build_dir/cache"
