#!/usr/bin/env bash
#
# install.sh — Bootstrap Hyprland Dotfiles (saatvik333)
# Works on a fresh Arch Linux system
#
# USAGE:
#   chmod +x install.sh
#   ./install.sh
#
set -euo pipefail

### CONFIGURATION
DOTFILES_REPO="https://github.com/Paracolax1/hyprland-dotfiles.git"
DOTFILES_DIR="$HOME/.local/share/hyprland-dotfiles"
CONFIG_DIR="$HOME/.config"

### COLORS
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

### HELPER FUNCTIONS
info()  { printf "%b[INFO]  %s%b\n"  "$GREEN" "$1" "$RESET"; }
warn()  { printf "%b[WARN]  %s%b\n"  "$YELLOW" "$1" "$RESET"; }

################################################################
# 1) SYSTEM PREPARATION
################################################################

info "Updating system packages..."
sudo pacman -Syu --noconfirm

info "Installing essential packages..."
sudo pacman -S --noconfirm \
  git base-devel \
  hyprland waybar wofi swaybg swww \
  pipewire pipewire-pulse pipewire-alsa xdg-desktop-portal-hyprland \
  networkmanager network-manager-applet \
  alacritty kitty foot \
  dunst mako \
  neovim starship \
  pavucontrol playerctl \
  wl-clipboard grim slurp \
  polkit polkit-kde-agent \
  python-pydbus \
  rofi \
  jq rsync

sudo pacman -S --noconfirm \
    mesa \
    vulkan-intel intel-media-driver \
    libva libva-intel-driver libva-utils

info "Enabling NetworkManager service"
sudo systemctl enable --now NetworkManager.service

################################################################
# 2) INSTALL AUR HELPER (paru)
################################################################
if ! command -v paru &> /dev/null; then
  info "Installing AUR helper (paru)..."
  cd /tmp
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
  cd -
else
  info "AUR helper (paru) already installed"
fi

################################################################
# 3) CLONE DOTFILES
################################################################
info "Cloning dotfiles repository"
if [ -d "$DOTFILES_DIR" ]; then
  warn "Existing dotfiles directory found, pulling updates"
  cd "$DOTFILES_DIR"
  git pull
else
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

################################################################
# 4) DEPLOY CONFIGURATION
################################################################
info "Linking dotfiles into ~/.config"
mkdir -p "$CONFIG_DIR"
cd "$DOTFILES_DIR"

# Use rsync to copy so we don’t overwrite unknown configs
rsync -a --info=progress2 \
  --exclude ".git" --exclude "scripts" \
  ./ "$CONFIG_DIR/"

################################################################
# 5) MAKE SCRIPTS EXECUTABLE
################################################################
info "Making custom scripts executable"
if [ -d "$CONFIG_DIR/scripts" ]; then
  find "$CONFIG_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;
fi

################################################################
# 6) OPTIONAL: GTK/THEME SUPPORT
################################################################
info "Installing GTK themes and icons (optional)"
paru -S --noconfirm materia-gtk-theme qogir-icon-theme

################################################################
# 7) SUMMARY & POST-INSTALL
################################################################
info "Dotfiles deployed successfully!"

echo ""
echo -e "${GREEN}Next steps:${RESET}"
echo "  • Reboot your system and select the Hyprland session"
echo "  • Run any dotfiles helper scripts inside ~/.config/scripts"
echo "  • Check ~/.config/hypr/hyprland.conf for keyboard layout and monitor settings"
echo "  • Configure wallpapers if needed (swww or swaybg)"
echo ""
echo "Enjoy your Hyprland setup! 🌶️"

exit 0
