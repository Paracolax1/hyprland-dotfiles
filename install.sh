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

PKGS=(
    git base-devel
    hyprland waybar wofi swaybg swww
    pipewire pipewire-pulse pipewire-alsa wireplumber
    # pulseaudio pulseaudio-alsa
    xdg-desktop-portal-hyprland xdg-desktop-portal xdg-desktop-portal-wlr
    networkmanager network-manager-applet
    alacritty kitty foot
    dunst mako
    neovim starship
    pavucontrol playerctl
    wl-clipboard grim slurp
    polkit polkit-kde-agent
    python-pydbus
    rofi
    jq
    rsync
    mesa
    vulkan-intel intel-media-driver
    libva libva-intel-driver libva-utils
    ttf-material-symbols-variable
    bottom
    bluez bluez-utils
    brightnessctl libnotify glib2 dconf
    imagemagick pacman-contrib
)


info "Installing essential packages..."
# Find packages that are not yet installed
MISSING_PKGS=()
for pkg in "${PKGS[@]}"; do
    if ! pacman -Qq "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

# Install missing packages in one command
if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    sudo pacman -S --noconfirm "${MISSING_PKGS[@]}"
else
    echo "[INFO] All packages already installed"
fi

systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo systemctl enable --now bluetooth

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
  --exclude ".git" \
  ./ "$CONFIG_DIR/"

################################################################
# 5) MAKE SCRIPTS EXECUTABLE
################################################################
info "Making custom scripts executable"
if [ -d "$DOTFILES_DIR/scripts" ]; then
  find "$DOTFILES_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;
fi

info "[INFO] Installing SF Pro & SF Mono fonts..."
"$DOTFILES_DIR/scripts/utils/install-sf-fonts.sh"
fc-cache -fv

################################################################
# 6) OPTIONAL: GTK/THEME SUPPORT
################################################################
info "Installing GTK themes and icons (optional)"

AUR_PKGS=(
    qogir-icon-theme-git
    materia-gtk-theme
    swaync bottom
    wallust-git
    yay
    vicinae-bin
    dust eza thunar minizip
    ttf-nerd-fonts-symbols
)

for pkg in "${AUR_PKGS[@]}"; do
    if ! paru -Q "$pkg" &>/dev/null; then
        paru -S --noconfirm "$pkg"
    else
        echo "[INFO] $pkg is already installed (AUR)"
    fi
done

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
