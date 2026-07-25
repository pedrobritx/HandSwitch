#!/usr/bin/env bash
#
# build-dmg.sh — Build HandSwitch.app and package it as a drag-to-install DMG.
#
# Usage:
#   ./Scripts/build-dmg.sh
#
# Environment overrides:
#   VERSION         Version string for the DMG filename. Defaults to the
#                   project's MARKETING_VERSION. A leading "v" is stripped, so
#                   a git tag like "v1.2.0" can be passed straight through.
#   SIGN_IDENTITY   Code signing identity. Unset (default) means ad-hoc ("-"),
#                   which produces an unsigned build that Gatekeeper will warn
#                   about. Set to a "Developer ID Application: …" identity to
#                   produce a distributable, notarizable build.
#   NOTARY_PROFILE  A `notarytool` keychain profile name. When set (and a real
#                   SIGN_IDENTITY is used), the DMG is submitted for
#                   notarization and the ticket is stapled.
#
# Output: dist/HandSwitch-<version>.dmg
#
set -euo pipefail

# ── Preconditions ────────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this script builds a macOS app and must run on macOS." >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found. Install Xcode and its command line tools." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT="HandSwitch.xcodeproj"
SCHEME="HandSwitch"
APP_NAME="HandSwitch"
CONFIGURATION="Release"

BUILD_DIR="$REPO_ROOT/build"
DERIVED_DIR="$BUILD_DIR/DerivedData"
EXPORT_DIR="$BUILD_DIR/export"
DIST_DIR="$REPO_ROOT/dist"
BACKGROUND="$REPO_ROOT/Resources/dmg/background.png"

APP_PATH="$EXPORT_DIR/$APP_NAME.app"

# ── Version ──────────────────────────────────────────────────────────────────
if [[ -z "${VERSION:-}" ]]; then
  VERSION="$(
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" \
      -showBuildSettings 2>/dev/null |
      awk -F' = ' '/[[:space:]]MARKETING_VERSION = /{print $2; exit}'
  )"
fi
VERSION="${VERSION#v}"
VERSION="${VERSION:-1.0}"

DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"

echo "▸ Building $APP_NAME $VERSION ($CONFIGURATION)"

# ── Build ────────────────────────────────────────────────────────────────────
# Build unsigned, then sign explicitly below. This keeps signing in one place
# and makes the ad-hoc vs. Developer ID paths identical apart from the identity.
rm -rf "$BUILD_DIR" "$APP_PATH"
mkdir -p "$EXPORT_DIR" "$DIST_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DIR" \
  -destination 'generic/platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

BUILT_APP="$DERIVED_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"
if [[ ! -d "$BUILT_APP" ]]; then
  echo "error: expected app not found at $BUILT_APP" >&2
  exit 1
fi
cp -R "$BUILT_APP" "$APP_PATH"

# ── Sign ─────────────────────────────────────────────────────────────────────
# A signature is required even for local use: macOS ties the Accessibility
# (TCC) grant that Instant mode depends on to the app's code signature.
IDENTITY="${SIGN_IDENTITY:--}"
ENTITLEMENTS="$REPO_ROOT/HandSwitch/Resources/HandSwitch.entitlements"

if [[ "$IDENTITY" == "-" ]]; then
  echo "▸ Ad-hoc signing (unsigned build — Gatekeeper will warn on other Macs)"
else
  echo "▸ Signing with: $IDENTITY"
fi

codesign --force --timestamp=none --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --sign "$IDENTITY" \
  "$APP_PATH"

codesign --verify --strict --verbose=2 "$APP_PATH"

# ── Package ──────────────────────────────────────────────────────────────────
rm -f "$DMG_PATH"

if command -v create-dmg >/dev/null 2>&1; then
  echo "▸ Creating DMG with create-dmg"
  STAGE_DIR="$BUILD_DIR/dmg-stage"
  rm -rf "$STAGE_DIR"
  mkdir -p "$STAGE_DIR"
  cp -R "$APP_PATH" "$STAGE_DIR/"

  # create-dmg adds the Applications drop-link itself, so the staging folder
  # must contain only the app. Geometry matches Tools/generate_dmg_background.py.
  # It exits non-zero if it cannot set the window's custom icon, which is not
  # fatal — the DMG is still valid — so tolerate that and verify below.
  create-dmg \
    --volname "$APP_NAME" \
    --background "$BACKGROUND" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 128 \
    --icon "$APP_NAME.app" 150 190 \
    --app-drop-link 450 190 \
    --hide-extension "$APP_NAME.app" \
    --no-internet-enable \
    "$DMG_PATH" \
    "$STAGE_DIR" || echo "  (create-dmg reported a non-fatal styling issue)"
else
  echo "▸ create-dmg not found — falling back to hdiutil (plain layout)"
  echo "  Install the styled version with: brew install create-dmg"
  STAGE_DIR="$BUILD_DIR/dmg-stage"
  rm -rf "$STAGE_DIR"
  mkdir -p "$STAGE_DIR"
  cp -R "$APP_PATH" "$STAGE_DIR/"
  ln -s /Applications "$STAGE_DIR/Applications"

  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGE_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"
fi

if [[ ! -f "$DMG_PATH" ]]; then
  echo "error: DMG was not produced at $DMG_PATH" >&2
  exit 1
fi

# ── Notarize (only meaningful with a real Developer ID) ──────────────────────
if [[ -n "${NOTARY_PROFILE:-}" && "$IDENTITY" != "-" ]]; then
  echo "▸ Notarizing (this can take a few minutes)"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  echo "▸ Notarized and stapled"
elif [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "▸ Skipping notarization: NOTARY_PROFILE is set but the build is ad-hoc signed."
fi

echo
echo "✅ $DMG_PATH"
if [[ "$IDENTITY" == "-" ]]; then
  echo "   Unsigned build. On another Mac, first launch needs:"
  echo '   System Settings > Privacy & Security -> "Open Anyway".'
fi
