#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="${BUILD_DIR:-$root/.build}"
app="${APP_OUTPUT:-$root/dist/Codex Allowance.app}"
mkdir -p "$build_dir/module-cache" "$app/Contents/MacOS"
export CLANG_MODULE_CACHE_PATH="$build_dir/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$build_dir/module-cache"
swift build --package-path "$root" --scratch-path "$build_dir" --cache-path "$build_dir/cache" -c release
bin_dir="$(swift build --package-path "$root" --scratch-path "$build_dir" --cache-path "$build_dir/cache" -c release --show-bin-path)"
cp "$bin_dir/CodexAllowance" "$app/Contents/MacOS/CodexAllowance"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>CodexAllowance</string>
<key>CFBundleIdentifier</key><string>local.dana.codex-allowance</string>
<key>CFBundleName</key><string>Codex Allowance</string>
<key>CFBundleDisplayName</key><string>Codex Allowance</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>2.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
printf 'Built %s\n' "$app"
