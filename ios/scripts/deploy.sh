#!/usr/bin/env bash
# One-command redeploy of Padel Pulse to the first paired iPad.
#
# Plug in the iPad, unlock it, then run:
#   ./ios/scripts/deploy.sh
# or, via the symlink, from anywhere:
#   padelpulse-deploy
#
# Needed on the free-tier developer account because app signatures expire
# every 7 days — this script replaces the 4-command memory lookup with one
# step that auto-detects the device.

set -euo pipefail

# Resolve repo root via the real script path (works even when invoked via
# a symlink in ~/bin).
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
IOS_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
BUNDLE_ID="com.padelpulse.app"
BUILD_LOG="/tmp/padelpulse-build.log"

cd "$IOS_DIR"

say() { printf "\033[1;36m→\033[0m %s\n" "$1"; }
ok()  { printf "\033[1;32m✓\033[0m %s\n" "$1"; }
die() { printf "\033[1;31m✗\033[0m %s\n" "$1" >&2; exit 1; }
warn(){ printf "\033[1;33m⚠\033[0m %s\n" "$1" >&2; }

say "Looking for a paired iPad..."
# Columns in `devicectl list devices`: Name, Hostname, UUID, State, Model...
# We want the first iPad with state "available (paired)".
device_line=$(xcrun devicectl list devices 2>/dev/null | awk '/iPad/ && /available \(paired\)/{print; exit}')
[[ -n "$device_line" ]] || die "No available iPad found. Plug it in, unlock it, and try again."

DEVICE_NAME=$(awk '{print $1}' <<<"$device_line")
DEVICECTL_ID=$(awk '{print $3}' <<<"$device_line")
ok "Found: $DEVICE_NAME ($DEVICECTL_ID)"

say "Regenerating Xcode project..."
xcodegen generate >/dev/null

say "Building for $DEVICE_NAME (this takes ~60s)..."
if ! xcodebuild -project PadelPulse.xcodeproj -scheme PadelPulse \
      -destination "platform=iOS,name=$DEVICE_NAME" \
      -configuration Debug -allowProvisioningUpdates build \
      >"$BUILD_LOG" 2>&1; then
  warn "Build failed. Last 20 lines:"
  tail -20 "$BUILD_LOG" >&2
  die "See full log: $BUILD_LOG"
fi

APP_PATH=$(ls -dt ~/Library/Developer/Xcode/DerivedData/PadelPulse-*/Build/Products/Debug-iphoneos/PadelPulse.app 2>/dev/null | head -1)
[[ -d "$APP_PATH" ]] || die "Built .app not found — check DerivedData path."

say "Installing to device..."
# devicectl prints a benign "No provider was found" warning we don't care about.
# Route stdout+stderr to the build log so the user sees a clean terminal.
if ! xcrun devicectl device install app --device "$DEVICECTL_ID" "$APP_PATH" >>"$BUILD_LOG" 2>&1; then
  warn "Install failed. Last 20 lines:"
  tail -20 "$BUILD_LOG" >&2
  die "See full log: $BUILD_LOG"
fi

say "Launching $BUNDLE_ID..."
if ! xcrun devicectl device process launch --device "$DEVICECTL_ID" "$BUNDLE_ID" >/dev/null 2>&1; then
  warn "Launch failed — iPad may be locked. Tap to unlock and re-run."
  exit 1
fi

ok "Padel Pulse deployed and launched on $DEVICE_NAME."
