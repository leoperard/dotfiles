#!/usr/bin/env bash
# scripts/install_alacritty.sh - Automated installer for Alacritty via GitHub release
set -euo pipefail

REPO="alacritty/alacritty"
APP_DIR="/Applications"
TARGET_APP="$APP_DIR/Alacritty.app"
BIN_DIR="$HOME/.local/bin"

echo "==> Fetching latest release information for $REPO..."
if command -v gh >/dev/null 2>&1; then
  TAG="$(gh release view -R "$REPO" --json tagName -q .tagName 2>/dev/null || true)"
else
  TAG=""
fi

if [[ -z "$TAG" ]]; then
  TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
fi

if [[ -z "$TAG" ]]; then
  echo "Error: Failed to determine latest release tag for $REPO." >&2
  exit 1
fi

echo "==> Latest release is $TAG"

# Check if currently installed and up to date
CURRENT_VERSION=""
if [[ -x "$TARGET_APP/Contents/MacOS/alacritty" ]]; then
  CURRENT_VERSION="$("$TARGET_APP/Contents/MacOS/alacritty" --version | awk '{print $2}')"
  CLEAN_TAG="${TAG#v}"
  if [[ "$CURRENT_VERSION" == "$CLEAN_TAG" ]]; then
    echo "Alacritty is already up to date ($CURRENT_VERSION)."
    exit 0
  fi
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  if [[ -n "${MOUNT_POINT:-}" && -d "${MOUNT_POINT:-}" ]]; then
    hdiutil detach "$MOUNT_POINT" -quiet || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

DMG_NAME="Alacritty-$TAG.dmg"
DMG_PATH="$TMP_DIR/$DMG_NAME"

echo "==> Downloading $DMG_NAME..."
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$DMG_NAME"
curl -fsSL -o "$DMG_PATH" "$DOWNLOAD_URL"

echo "==> Mounting DMG..."
MOUNT_POINT="$(hdiutil attach "$DMG_PATH" -nobrowse -mountrandom "$TMP_DIR" | awk '/\/dmg\./ {print $NF}')"
if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
  echo "Error: Failed to mount disk image." >&2
  exit 1
fi

echo "==> Installing Alacritty to $APP_DIR..."
rm -rf "$TARGET_APP"
cp -R "$MOUNT_POINT/Alacritty.app" "$APP_DIR/"

echo "==> Clearing macOS Gatekeeper quarantine attribute..."
xattr -dr com.apple.quarantine "$TARGET_APP" 2>/dev/null || true

echo "==> Linking CLI binary to $BIN_DIR/alacritty..."
mkdir -p "$BIN_DIR"
ln -sf "$TARGET_APP/Contents/MacOS/alacritty" "$BIN_DIR/alacritty"

echo "==> Setup completed successfully!"
"$TARGET_APP/Contents/MacOS/alacritty" --version
