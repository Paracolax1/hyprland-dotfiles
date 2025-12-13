#!/usr/bin/env bash
#
# install-sf-fonts.sh — Install or update SF Pro & SF Mono fonts
# Efficient, idempotent, no repeated cloning
#

set -euo pipefail

REPO="https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git"
CACHE_DIR="$HOME/.cache/sf-fonts"
FONT_DIR="$HOME/.local/share/fonts/SF-Pro"

echo "[INFO] Checking SF Pro & SF Mono fonts..."

# Ensure required commands exist
for cmd in git fc-cache; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "[ERROR] Required command not found: $cmd"
    exit 1
  }
done

# Clone once
if [[ ! -d "$CACHE_DIR/.git" ]]; then
  echo "[INFO] Cloning SF fonts repository (one-time)..."
  mkdir -p "$(dirname "$CACHE_DIR")"
  git clone --depth=1 "$REPO" "$CACHE_DIR"
else
  echo "[INFO] Updating SF fonts repository..."
  git -C "$CACHE_DIR" fetch --quiet
fi

# Check if there are updates
LOCAL_HASH="$(git -C "$CACHE_DIR" rev-parse HEAD)"
REMOTE_HASH="$(git -C "$CACHE_DIR" rev-parse @{u} 2>/dev/null || echo "$LOCAL_HASH")"

if [[ "$LOCAL_HASH" != "$REMOTE_HASH" ]]; then
  echo "[INFO] New fonts available, pulling updates..."
  git -C "$CACHE_DIR" pull --quiet
  UPDATED=true
else
  UPDATED=false
fi

# Install fonts only if missing or updated
if [[ ! -d "$FONT_DIR" || "$UPDATED" == true ]]; then
  echo "[INFO] Installing font files..."
  mkdir -p "$FONT_DIR"

  find "$CACHE_DIR" -type f \
    \( -iname "*.ttf" -o -iname "*.otf" \) \
    -exec cp -f {} "$FONT_DIR"/ \;

  echo "[INFO] Rebuilding font cache..."
  fc-cache -f "$FONT_DIR"
else
  echo "[INFO] Fonts already installed and up to date."
fi

echo "[DONE] SF Pro & SF Mono fonts are ready."
