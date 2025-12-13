#!/usr/bin/env bash
#
# install-sf-fonts.sh — Install SF Pro & SF Mono fonts
# (pulls from a publicly mirrored GitHub repo)
#
# USAGE:
#   chmod +x install-sf-fonts.sh
#   ./install-sf-fonts.sh

set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts/SF-Pro"
REPO="https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git"

echo "[INFO] Installing SF Pro & SF Mono fonts..."

# Create local font directory
mkdir -p "$FONT_DIR"

# Clone the repository (temp)
TMPDIR="$(mktemp -d)"
git clone "$REPO" "$TMPDIR"

echo "[INFO] Copying font files..."
find "$TMPDIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONT_DIR"/ \;

echo "[INFO] Cleaning up..."
rm -rf "$TMPDIR"

echo "[INFO] Rebuilding font cache..."
fc-cache -fv "$FONT_DIR"

echo "[DONE] SF Pro & SF Mono fonts installed to $FONT_DIR"
echo "You can now set them via fc-list or in your Hyprland variables.conf file."
