#!/usr/bin/env bash
# run-ios.sh - build StudyForge, install it on a simulator and launch it.
#
# Xcode 27 replaced Simulator.app with Device Hub, so "open -a Simulator" no
# longer works. This script drives the whole cycle from the command line, which
# is what makes the app runnable from the VS Code terminal and from CI.
#
# Usage:
#   bash tools/run-ios.sh                  # build + install + launch (iPhone 17)
#   bash tools/run-ios.sh "iPhone Air"     # pick the simulator by name
#
# Environment:
#   SIM_RUNTIME  runtime used only when the device has to be created
#                (default com.apple.CoreSimulator.SimRuntime.iOS-27-0)

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

SIM_NAME="${1:-iPhone 17}"
SIM_DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.${SIM_NAME// /-}"
SIM_RUNTIME="${SIM_RUNTIME:-com.apple.CoreSimulator.SimRuntime.iOS-27-0}"

PROJECT="ios/StudyForge/StudyForge.xcodeproj"
SCHEME="StudyForge"
BUNDLE_ID="com.saleh.studyforge"
DEVICE_HUB="/Applications/Xcode.app/Contents/Applications/DeviceHub.app"

die()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$1"; }
step() { printf '\033[36m==> %s\033[0m\n' "$1"; }

[[ -d "$PROJECT" ]] || die "cannot find $PROJECT (run from the repo root)"

# ── 1. resolve the simulator, creating it on first run ────────────────────
step "Resolving simulator '$SIM_NAME'"
UDID="$(xcrun simctl list devices available \
        | sed -n "s/^ *$SIM_NAME (\([0-9A-F-]\{36\}\)) (.*/\1/p" \
        | head -1)"

if [[ -z "$UDID" ]]; then
  step "No device named '$SIM_NAME' yet, creating it"
  UDID="$(xcrun simctl create "$SIM_NAME" "$SIM_DEVICE_TYPE" "$SIM_RUNTIME")"
fi
ok "simulator $SIM_NAME ($UDID)"

# ── 2. boot it and bring up the device UI ─────────────────────────────────
step "Booting"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

# Xcode 27: Device Hub is the device UI. Not fatal if it cannot open (headless
# or CI), because simctl can install, launch and screenshot without it.
open -a "$DEVICE_HUB" 2>/dev/null || true

# ── 3. build ──────────────────────────────────────────────────────────────
step "Building $SCHEME"
xcodebuild -project "$PROJECT" \
           -scheme "$SCHEME" \
           -configuration Debug \
           -destination "id=$UDID" \
           build CODE_SIGNING_ALLOWED=NO

# ── 4. install and launch ─────────────────────────────────────────────────
step "Resolving the built product"
APP_PATH="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
            -destination "id=$UDID" -showBuildSettings 2>/dev/null \
            | awk '/ BUILT_PRODUCTS_DIR = /{d=$3} / FULL_PRODUCT_NAME = /{n=$3} END{print d"/"n}')"
[[ -d "$APP_PATH" ]] || die "no .app found at '$APP_PATH'"

step "Installing $(basename "$APP_PATH")"
xcrun simctl install "$UDID" "$APP_PATH"

step "Launching $BUNDLE_ID"
xcrun simctl launch "$UDID" "$BUNDLE_ID"

ok "StudyForge is running on '$SIM_NAME'"
