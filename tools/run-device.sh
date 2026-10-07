#!/usr/bin/env bash
# run-device.sh - build StudyForge, install it on a real iPhone and launch it.
#
# tools/run-ios.sh covers the simulator. A real device needs two things the
# simulator does not: a signing team, and a bundle identifier that your own
# Apple ID is allowed to provision. Keeping those two values inside the Xcode
# project forces a long-lived "device" branch to fork away from develop, and
# that fork is exactly how the phone ends up running last month's build.
#
# Instead, both are passed as build settings on the command line, so the build
# always comes from the commit you are standing on. To get the latest:
#
#   git switch develop && git pull && bash tools/run-device.sh
#
# Usage:
#   bash tools/run-device.sh                 # first paired physical iPhone
#   bash tools/run-device.sh "Saleh iPhone"  # pick the device by name
#   bash tools/run-device.sh --list          # show paired devices, then exit
#
# Setup (once per machine):
#   cp tools/device.local.env.example tools/device.local.env
#   # then fill in DEVICE_BUNDLE_ID and DEVICE_TEAM
#
# Environment (a value set here overrides the file):
#   DEVICE_BUNDLE_ID   identifier the app is signed and installed as
#   DEVICE_TEAM        10-character Apple Developer team identifier

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ -f tools/device.local.env ]]; then
  # shellcheck source=/dev/null
  source tools/device.local.env
fi

PROJECT="ios/StudyForge/StudyForge.xcodeproj"
SCHEME="StudyForge"
BUNDLE_ID="${DEVICE_BUNDLE_ID:-com.studyforge.app}"
TEAM="${DEVICE_TEAM:-}"
DEVICE_NAME="${1:-iPhone}"

die()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }
warn() { printf '\033[33m! %s\033[0m\n' "$1" >&2; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$1"; }
step() { printf '\033[36m==> %s\033[0m\n' "$1"; }

[[ -d "$PROJECT" ]] || die "cannot find $PROJECT (run this from the repo root)"

if [[ "$DEVICE_NAME" == "--list" ]]; then
  xcrun devicectl list devices
  exit 0
fi

# ── 1. resolve the physical device ────────────────────────────────────────
step "Resolving device '$DEVICE_NAME'"
ROW="$(xcrun devicectl list devices 2>/dev/null \
        | grep 'physical' \
        | grep -iE "^${DEVICE_NAME}([[:space:]]|$)" \
        | head -1 || true)"

if [[ -z "$ROW" ]]; then
  die "no physical device matching '$DEVICE_NAME' is paired with this Mac.
  Plug the iPhone in, unlock it and tap Trust if it asks, then check with:
    bash tools/run-device.sh --list"
fi

UDID="$(printf '%s' "$ROW" | grep -oE '[0-9A-F]{8}-[0-9A-F]{8,16}' | head -1)"
[[ -n "$UDID" ]] || die "could not read a UDID out of: $ROW"

if printf '%s' "$ROW" | grep -qi 'unavailable'; then
  die "device '$DEVICE_NAME' ($UDID) is paired but not reachable.
  Plug it in, unlock it, keep it awake, then run this again."
fi
ok "device $DEVICE_NAME ($UDID)"

# ── 2. the signing values ─────────────────────────────────────────────────
[[ -n "$TEAM" ]] || die "no Apple team id.
  cp tools/device.local.env.example tools/device.local.env
  then set DEVICE_TEAM to the 10-character team id from
  Xcode > Settings > Accounts (it is also on your developer certificate)."

step "Signing as $BUNDLE_ID (team $TEAM)"

# ── 3. build for the device ───────────────────────────────────────────────
# PRODUCT_BUNDLE_IDENTIFIER and DEVELOPMENT_TEAM are set here rather than in
# the project, so this build never diverges from develop. The tests target is
# not built: the scheme marks it buildForRunning = NO.
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
SHA="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

step "Building $SCHEME from $BRANCH @ $SHA"
xcodebuild -project "$PROJECT" \
           -scheme "$SCHEME" \
           -configuration Debug \
           -destination "id=$UDID" \
           -allowProvisioningUpdates \
           build \
           PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
           DEVELOPMENT_TEAM="$TEAM"

# ── 4. install and launch ─────────────────────────────────────────────────
step "Resolving the built product"
APP_PATH="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
            -sdk iphoneos -showBuildSettings 2>/dev/null \
            | awk '/ BUILT_PRODUCTS_DIR = /{d=$3} / FULL_PRODUCT_NAME = /{n=$3} END{print d"/"n}')"
[[ -d "$APP_PATH" ]] || die "no .app found at '$APP_PATH'"

step "Installing $(basename "$APP_PATH")"
xcrun devicectl device install app --device "$UDID" "$APP_PATH"

step "Launching $BUNDLE_ID"
if xcrun devicectl device process launch --device "$UDID" "$BUNDLE_ID" >/dev/null 2>&1; then
  ok "StudyForge $SHA ($BRANCH) is running on '$DEVICE_NAME'"
else
  # The install above is the part that had to succeed: a LOCKED phone refuses to launch
  # anything (SBMainWorkspace: "the device was not, or could not be, unlocked"), which is a
  # state the student clears by tapping the icon, not a build failure.
  warn "installed, but iOS refused to launch it."
  ok "StudyForge $SHA ($BRANCH) is installed on '$DEVICE_NAME'. Unlock it and tap the icon."
fi

if [[ "$BRANCH" != "develop" ]]; then
  warn "that build came from '$BRANCH', not 'develop'.
  For the latest: git switch develop && git pull && bash tools/run-device.sh"
fi
