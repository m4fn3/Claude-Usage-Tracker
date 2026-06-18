#!/usr/bin/env bash
#
# Build "Claude Usage" from source (this checkout, incl. merged PR #220)
# and install it to /Applications, then launch it.
#
# Usage:
#   ./build-and-install.sh            # build current checkout + install
#   ./build-and-install.sh --pull     # git pull upstream main first (keeps merged PRs), then build + install
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$REPO_DIR/Claude Usage.xcodeproj"
SCHEME="Claude Usage"
CONFIG="Release"
DERIVED="$REPO_DIR/build"
APP_NAME="Claude Usage.app"
BUILT_APP="$DERIVED/Build/Products/$CONFIG/$APP_NAME"
DEST_APP="/Applications/$APP_NAME"

cd "$REPO_DIR"

if [[ "${1:-}" == "--pull" ]]; then
  echo "==> Pulling latest upstream main (merge; keeps locally-merged PRs)..."
  git pull --no-edit origin main
fi

echo "==> Building \"$SCHEME\" ($CONFIG)..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED" \
  -skipPackagePluginValidation \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  build

if [[ ! -d "$BUILT_APP" ]]; then
  echo "ERROR: build product not found at: $BUILT_APP" >&2
  exit 1
fi

echo "==> Quitting running instance (if any)..."
osascript -e 'quit app "Claude Usage"' 2>/dev/null || true
sleep 2
pkill -f "/Applications/$APP_NAME/Contents/MacOS/Claude Usage" 2>/dev/null || true
sleep 1

echo "==> Installing to $DEST_APP..."
rm -rf "$DEST_APP"
cp -R "$BUILT_APP" "$DEST_APP"

echo "==> Verifying signature..."
codesign --verify --deep --strict "$DEST_APP"

VER="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$DEST_APP/Contents/Info.plist" 2>/dev/null || echo '?')"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$DEST_APP/Contents/Info.plist" 2>/dev/null || echo '?')"

echo "==> Launching..."
open "$DEST_APP"

echo "✅ Installed \"Claude Usage\" v$VER (build $BUILD) and launched."
