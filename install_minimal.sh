#!/usr/bin/env bash
#
# install.sh — Bootstrap Hyprland Dotfiles
# Works on a fresh Arch Linux system
#
# USAGE:
#   chmod +x install.sh
#   ./install.sh
#
set -euo pipefail

### CONFIGURATION
readonly DOTFILES_REPO="https://github.com/Paracolax1/hyprland-dotfiles.git"
readonly DOTFILES_DIR="$HOME/.local/share/hyprland-dotfiles"
readonly CONFIG_DIR="$HOME/.config"

### COLORS
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

### PACKAGES
readonly PACMAN_PACKAGES=(
    #### CORE
    hyprland                    # Compositor
    # xdg-desktop-portal          # Flatpak sandbox portal manager (e.g. select file prompt)
    # xdg-desktop-portal-hyprland # Flatpak sandbox portals for Hyprland specific features

    # pipewire        # Audio manager
    # wireplumber
    # pipewire-pulse  # PulseAudio compatbility
    # pipewire-alsa   # ALSA compatibility

    networkmanager  # Network manager
    polkit          # Authorization framework

    mesa        # OpenGL
    qt5-wayland # qt5 translation plugin
    qt6-wayland # qt6 translation plugin
    glib2       # Clang helper library
    dconf       # key-value config system

    #### DESKTOP
    waybar  # Customizable taskbar
    # wofi    # Program launcher
    swww     # Wallpaper manager
    # dunst   # Run custom scripts on notifications
    # gtklock # Lockscreen

    # wl-clipboard    # Wayland clipboard manager with cli commands
    # grim            # Screenshot utility
    # slurp           # Wayland region selector
    libnotify       # Library for sending desktop notifications
    brightnessctl   # CLI for controlling display brightness

    alacritty   # Terminal Emulator
    # pavucontrol # Audio GUI
    # playerctl   # Media key control
    # ffmpeg      # Multi-media processor

    #### GRAPHICS/DRIVERS (INTEL-SPECIFIC)
    # vulkan-intel        # Intel GPU Vulkan drivers
    # intel-media-driver  # Full codecs drivers (e.g. H.264, H.265)
    # libva-intel-driver  # Slim codecs drivers (e.g. AV1, VP9)
    # libva               # Video Acceleration API library
    # libva-utils         # CLI tools for libva

    #### BLUETOOTH
    # bluez       # Bluetooth protocol stack
    # bluez-utils # CLI tools for bluez

    #### UTILITIES
    # neovim              # Modern vim refactor
    # starship            # Shell prompt (shows info, git branch/status etc)
    # jq                  # CLI json tool
    # unzip               # Unzip cli tool
    pacman-contrib      # Contributed scripts to pacman
    # fastfetch           # Terminal system info fetcher (shows info on new terminal)
    # bottom              # TUI system monitor
    btop                # TUI system monitor
    yazi                # TUI file manager
    # zathura             # Document viewer
    # zathura-pdf-mupdf   # PDF extension
    # imagemagick         # image something
    # bc

    #### FONTS
    ttf-jetbrains-mono-nerd
    ttf-material-symbols-variable


    #### UNORGANISED
    hypridle
    hyprpolkitagent
    # udiskie
    # easyeffects
    # hyprpicker
    # thefuck
    # cpio
    # cmake
    # flatpak
    # gnome-software
    # linux-headers
    # fuse2
    # gtkmm-4.0
    # pcsclite
    # libcanberra
    # gnome-disk-utility
    # docker
    # docker-compose
    # go

    ashai-desktop-meta
    arch-install-scripts
    hyprgraphics



    # hyprland waybar wofi swaybg swww
    # pipewire pipewire-pulse pipewire-alsa wireplumber
    # # pulseaudio pulseaudio-alsa
    # xdg-desktop-portal-hyprland xdg-desktop-portal xdg-desktop-portal-wlr
    # networkmanager network-manager-applet
    # alacritty kitty foot
    # dunst mako
    # neovim starship
    # pavucontrol playerctl
    # wl-clipboard grim slurp
    # polkit polkit-kde-agent polkit-gnome
    # python-pydbus
    # rofi
    # jq
    # rsync
    # mesa
    # vulkan-intel intel-media-driver
    # libva libva-intel-driver libva-utils
    # ttf-material-symbols-variable
    # bottom
    # bluez bluez-utils
    # brightnessctl libnotify glib2 dconf
    # imagemagick pacman-contrib
    # fastfetch yazi qt5-wayland qt6-wayland ffmpeg
    # unzip gtklock zathura zathura-pdf-mupdf
    # ttf-jetbrains-mono-nerd curl
)

readonly AUR_PACKAGES=(
    qogir-icon-theme-git
    # swaync          # Sway notification center
    wallust-git     # Color palette maker
    vicinae-bin     # Application launcher
    # dust            # CLI disk usage overview
    # thunar          # GUI file manager
    # minizip         # Zips files
    nerd-fonts  # Nerd fonts
    nerd-fonts-sf-mono-ligatures

    waytrogen
    # hyprswitch
    # bongocat
    # wlogout
    # visual-studio-code-bin
    ncurses5-compat-libs
    # mware-keymaps
    # vmware-workstation
)

readonly FLATPAK_APPS=(
    # com.google.Chrome
    # com.github.tchx84.Flatseal
    # com.discordapp.Discord
    # com.spotify.Client
    # com.obsproject.Studio
    # org.videolan.VLC
    # org.audacityteam.Audacity
    # org.mozilla.firefox
    # com.valvesoftware.Steam
)

TMP_BUILD_DIR=""

### HELPER FUNCTIONS
msg()   { printf "%b[INFO]  %s%b\n"  "$GREEN" "$1" "$RESET"; }
info()  { printf "%b[INFO]  %s%b\n"  "$BLUE" "$1" "$RESET"; }
warn()  { printf "%b[WARN]  %s%b\n"  "$YELLOW" "$1" "$RESET"; }
error()  { printf "%b[ERROR] %s%b\n"  "$RED" "$1" "$RESET"; }
fatal() {
    error "$1"
    error "Installation failed"
    exit 1
}

################################################################
# CLEANUP FUNCTION
################################################################

cleanup_temp_files() {
  if [[ -n "${TMP_BUILD_DIR}" ]] && [[ -d "${TMP_BUILD_DIR}" ]]; then
    info "Cleaning up temporary build directory..."
    rm -rf "${TMP_BUILD_DIR}" 2>/dev/null || true
  fi
}

cleanup_on_exit() {
  local exit_code=$?
  cleanup_temp_files
  
  if [[ ${exit_code} -ne 0 ]]; then
    error "Script exited with error code: ${exit_code}"
  fi
}

cleanup_on_error() {
  local line_no=$1
  error "Error occurred on line ${line_no}"
  cleanup_on_exit
}

################################################################
# UTILITY FUNCTIONS
################################################################

check_not_root() {
  if [[ ${EUID} -eq 0 ]]; then
    fatal "Do not run this script as root. Run as a regular user with sudo privileges."
  fi
}

check_sudo() {
  info "Verifying sudo privileges..."
  if ! sudo -v; then
    fatal "Sudo privileges required. Please ensure you have sudo access."
  fi
  
  msg "Sudo privileges verified."
}


verify_binary() {
  local binary="$1"
  if ! command -v "${binary}" &>/dev/null; then
    error "Binary '${binary}' not found in PATH."
    return 1
  fi
  return 0
}

################################################################
# PACKAGE MANAGEMENT
################################################################

update_system() {
  info "Updating system packages..."
  if sudo pacman -Syu --noconfirm; then
    msg "System updated successfully."
  else
    fatal "Failed to update system packages."
  fi
}

install_base_tools() {
  info "Installing base development tools..."
  if sudo pacman -S --needed --noconfirm git base-devel curl rsync rustup; then
    msg "Base tools installed."
  else
    fatal "Failed to install base development tools."
  fi

  if rustup default stable; then
    msg "Installed rustup successfully"
  else
    fatal "Failed to install rustup"
  fi
}

install_yay() {
    if verify_binary yay; then
       info "Yay already installed"
       return 0
    fi

    if sudo pacman -S --noconfirm yay; then
        msg "Yay installed from official repository."
        return 0
    fi

    local tmp_build_dir

    info "yay not in official repos, building from AUR..."
    tmp_build_dir="$(mktemp -d)"

    if [[ ! -d "${tmp_build_dir}" ]]; then
        fatal "Failed to create temporary directory for yay build"
    fi

    info "Cloning yay repository (this may take a moment)..."
    if ! git clone --depth=1 https://aur.archlinux.org/yay-bin.git "${tmp_build_dir}"; then
        fatal "Failed to clone yay repository."
    fi

    info "Building yay package (this may take a few minutes)..."
    if ! (cd "${tmp_build_dir}" && makepkg -si --noconfirm); then
        fatal "Failed to build and install yay."
    fi

    info "Cleaning up yay build directory..."
    rm -rf "${tmp_build_dir}"

    if verify_binary yay; then
        msg "yay installed successfully from AUR."
    else
        fatal "yay installation completed but binary not found."
    fi
}

install_pacman_packages() {
  info "Installing official repository packages..."
  info "This may take several minutes..."
  
  if sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"; then
    msg "Official packages installed successfully."
  else
    fatal "Failed to install official repository packages."
  fi
}

install_aur_packages() {
  info "Installing AUR packages using yay..."
  info "This may take several minutes..."
  
  if yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"; then
    msg "AUR packages installed successfully."
  else
    fatal "Failed to install AUR packages."
  fi
}

install_colloid_theme() {
  local repo_url="https://github.com/vinceliuice/Colloid-gtk-theme"
  local state_dir="$HOME/.local/state/colloid-theme"
  local version_file="$state_dir/installed_commit"
  local remote_commit theme_dir

  mkdir -p "$state_dir"

  info "Checking Colloid GTK theme version..."

  remote_commit="$(git ls-remote "$repo_url" HEAD | awk '{print $1}')" || {
    warn "Failed to check remote Colloid theme version"
    return 1
  }

  if [[ -f "$version_file" ]] && [[ "$(cat "$version_file")" == "$remote_commit" ]]; then
    info "Colloid GTK theme is already up to date."
    return 0
  fi

  info "Updating Colloid GTK theme..."

  theme_dir="$(mktemp -d)" || {
    warn "Failed to create temporary directory"
    return 1
  }

  if ! git clone --depth=1 "$repo_url" "$theme_dir"; then
    rm -rf "$theme_dir"
    warn "Failed to clone Colloid theme repository"
    return 1
  fi

  if ! (cd "$theme_dir" && ./install.sh --libadwaita --tweaks all rimless); then
    rm -rf "$theme_dir"
    warn "Failed to install Colloid theme (default variant)"
    return 1
  fi

  if ! (cd "$theme_dir" && ./install.sh --libadwaita --theme grey --tweaks black rimless); then
    rm -rf "$theme_dir"
    warn "Failed to install Colloid theme (grey-black variant)"
    return 1
  fi

  echo "$remote_commit" > "$version_file"
  rm -rf "$theme_dir"

  msg "Colloid GTK theme installed / updated successfully."
}


install_rosepine_theme() {
  local repo_url="https://github.com/Fausto-Korpsvart/Rose-Pine-GTK-Theme"
  local state_dir="$HOME/.local/state/rosepine-gtk-theme"
  local version_file="$state_dir/installed_commit"
  local remote_commit theme_dir

  mkdir -p "$state_dir"

  info "Checking Rose Pine GTK theme version..."

  remote_commit="$(git ls-remote "$repo_url" HEAD | awk '{print $1}')" || {
    warn "Failed to check remote Rose Pine theme version"
    return 1
  }

  if [[ -f "$version_file" ]] && [[ "$(cat "$version_file")" == "$remote_commit" ]]; then
    info "Rose Pine GTK theme is already up to date."
    return 0
  fi

  info "Installing / updating Rose Pine GTK theme..."

  theme_dir="$(mktemp -d)" || {
    warn "Failed to create temporary directory for Rose Pine theme"
    return 1
  }

  if ! git clone --depth=1 "$repo_url" "$theme_dir"; then
    rm -rf "$theme_dir"
    warn "Failed to clone Rose Pine theme repository."
    return 1
  fi

  if ! (cd "$theme_dir/themes" && ./install.sh --libadwaita --tweaks moon macos); then
    rm -rf "$theme_dir"
    warn "Failed to install Rose Pine theme."
    return 1
  fi

  echo "$remote_commit" > "$version_file"
  rm -rf "$theme_dir"

  msg "Rose Pine GTK theme installed / updated successfully."
}


install_osaka_theme() {
  local repo_url="https://github.com/Fausto-Korpsvart/Osaka-GTK-Theme"
  local state_dir="$HOME/.local/state/osaka-gtk-theme"
  local version_file="$state_dir/installed_commit"
  local remote_commit theme_dir

  mkdir -p "$state_dir"

  info "Checking Osaka GTK theme version..."

  remote_commit="$(git ls-remote "$repo_url" HEAD | awk '{print $1}')" || {
    warn "Failed to check remote Osaka theme version"
    return 1
  }

  if [[ -f "$version_file" ]] && [[ "$(cat "$version_file")" == "$remote_commit" ]]; then
    info "Osaka GTK theme is already up to date."
    return 0
  fi

  info "Installing / updating Osaka GTK theme..."

  theme_dir="$(mktemp -d)" || {
    warn "Failed to create temporary directory for Osaka theme"
    return 1
  }

  if ! git clone --depth=1 "$repo_url" "$theme_dir"; then
    rm -rf "$theme_dir"
    warn "Failed to clone Osaka theme repository."
    return 1
  fi

  if ! (cd "$theme_dir/themes" && ./install.sh --libadwaita --tweaks solarized macos); then
    rm -rf "$theme_dir"
    warn "Failed to install Osaka theme."
    return 1
  fi

  echo "$remote_commit" > "$version_file"
  rm -rf "$theme_dir"

  msg "Osaka GTK theme installed / updated successfully."
}

install_gtk_themes() {
  info "Installing GTK themes..."
  info "This may take several minutes..."
  
  local themes_dir="${HOME}/.themes"
  mkdir -p "${themes_dir}"
  
  local installed_themes=()
  local failed_themes=()
  
  if install_colloid_theme; then
    installed_themes+=("Colloid")
  else
    failed_themes+=("Colloid")
  fi
  
  if install_rosepine_theme; then
    installed_themes+=("Rose-Pine")
  else
    failed_themes+=("Rose-Pine")
  fi
  
  if install_osaka_theme; then
    installed_themes+=("Osaka")
  else
    failed_themes+=("Osaka")
  fi
  
  if [[ ${#installed_themes[@]} -gt 0 ]]; then
    msg "Successfully installed ${#installed_themes[@]} GTK theme(s): ${installed_themes[*]}"
  fi
  
  if [[ ${#failed_themes[@]} -gt 0 ]]; then
    warn "Failed to install ${#failed_themes[@]} GTK theme(s): ${failed_themes[*]}"
    warn "You can manually install these themes later if needed."
  fi
  
  if [[ ${#installed_themes[@]} -eq 0 ]]; then
    error "All GTK themes failed to install."
    return 1
  fi
  
  return 0
}

install_colloid_icons() {
  local repo_url="https://github.com/vinceliuice/Colloid-icon-theme"
  local state_dir="$HOME/.local/state/colloid-icon-theme"
  local version_file="$state_dir/installed_commit"
  local remote_commit icons_dir

  mkdir -p "$state_dir"

  info "Checking Colloid icon theme version..."

  remote_commit="$(git ls-remote "$repo_url" HEAD | awk '{print $1}')" || {
    warn "Failed to check remote Colloid icon theme version"
    return 1
  }

  if [[ -f "$version_file" ]] && [[ "$(cat "$version_file")" == "$remote_commit" ]]; then
    info "Colloid icon theme is already up to date."
    return 0
  fi

  info "Installing / updating Colloid icon theme..."

  icons_dir="$(mktemp -d)" || {
    warn "Failed to create temporary directory for Colloid icons"
    return 1
  }

  if ! git clone --depth=1 "$repo_url" "$icons_dir"; then
    rm -rf "$icons_dir"
    warn "Failed to clone Colloid icon theme repository."
    return 1
  fi

  if ! (cd "$icons_dir" && ./install.sh --scheme all --bold); then
    rm -rf "$icons_dir"
    warn "Failed to install Colloid icon theme."
    return 1
  fi

  echo "$remote_commit" > "$version_file"
  rm -rf "$icons_dir"

  msg "Colloid icon theme installed / updated successfully."
}

install_icon_themes() {
  info "Installing icon themes..."
  info "This may take several minutes..."
  
  local icons_dir="${HOME}/.icons"
  mkdir -p "${icons_dir}"
  
  local installed_icons=()
  local failed_icons=()
  
  if install_colloid_icons; then
    installed_icons+=("Colloid")
  else
    failed_icons+=("Colloid")
  fi
  
  if [[ ${#installed_icons[@]} -gt 0 ]]; then
    msg "Successfully installed ${#installed_icons[@]} icon theme(s): ${installed_icons[*]}"
  fi
  
  if [[ ${#failed_icons[@]} -gt 0 ]]; then
    warn "Failed to install ${#failed_icons[@]} icon theme(s): ${failed_icons[*]}"
    warn "You can manually install these icon themes later if needed."
  fi
  
  if [[ ${#installed_icons[@]} -eq 0 ]]; then
    error "All icon themes failed to install."
    return 1
  fi
  
  return 0
}

install_fonts() {
    info "Installing SF Pro & SF Mono fonts..."
    if "$DOTFILES_DIR/scripts/utils/install-sf-fonts.sh"; then
        msg "Installed SF Pro & SF Mono Fonts successfully"
    else
        error "Failed to install SF Pro & SF Mono fonts. Continuing."
    fi

    info "Refreshing font cache"
    if ! fc-cache -fv; then
        error "Failed to refresh font cache, continuing."
    fi
}

clone_dotfiles() {
    info "Cloning dotfiles repo"
    if ! git clone --depth=1 "$DOTFILES_REPO" "$DOTFILES_DIR"; then
        fatal "Failed to clone dotfiles repository."
    fi

    if [[ ! -d "${DOTFILES_DIR}/.git" ]]; then
        fatal "Repository cloned but .git not found, could be corrupted."
    fi

    msg "Dotfiles cloned successfully."
}

clone_or_update_dotfiles() {
    if [[ -d "${DOTFILES_DIR}/.git" ]]; then
        info "Existing dotfiles directory found, pulling updates"
        cd "$DOTFILES_DIR"
        if ! git pull; then
            warn "Failed to update dotfiles"
            rm -rf "${DOTFILES_DIR}"
            clone_dotfiles
        else
            msg "Dotfiles updated successfully."
        fi
    elif [[ -d "${DOTFILES_DIR}" ]]; then
        warn "Dotfiles directory exists but is not a git repository"
        rm -rf "${DOTDIR}"
        clone_dotfiles
    else
        clone_dotfiles
    fi

    info "Updating git submodules..."
    cd "$DOTFILES_DIR"
    if git submodule update --init --recursive; then
        msg "Submodules updated"
    else
        warn "Failed to update submodules. Continuing."
    fi

    info "Syncing dotfiles with ~/.config"
    mkdir -p "$CONFIG_DIR"
    cd "$DOTFILES_DIR"

    # Use rsync to copy so we don’t overwrite unknown configs
    if rsync -a --info=progress2 \
    --exclude ".git" \
    ./ "$CONFIG_DIR/"; then
        msg "Synced dotfiles successfully"
    else
        fatal "Failed to sync dotfiles"
    fi

    info "Making custom scripts executable"
    if [ -d "$DOTFILES_DIR/scripts" ]; then
        if find "$DOTFILES_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;; then
            msg "Made custom scripts executable successfully"
        else
            error "Failed to make custom scripts executable, continuing"
        fi
    else
        msg "No scripts directory found. Ignoring."
    fi
}

install_wallpapers() {
  if [[ -d "${DOTFILES_DIR}/wallpapers" ]]; then
    info "Installing wallpapers..."
    local wallpaper_dir="${HOME}/Pictures/Wallpapers"
    mkdir -p "${wallpaper_dir}"

    shopt -s nullglob
    local wallpapers=("${DOTFILES_DIR}/wallpapers/"*)
    shopt -u nullglob

    if [[ ${#wallpapers[@]} -gt 0 ]]; then
      if cp -r "${DOTFILES_DIR}/wallpapers/"* "${wallpaper_dir}/" 2>/dev/null; then
        msg "Wallpapers installed to: ${wallpaper_dir}"
      else
        warn "Failed to copy wallpapers."
      fi
    else
      info "No wallpapers found in repository."
    fi
  else
    info "No wallpapers directory found in repository."
  fi
}

create_systemd_services() {
    info "Creating gtklock service for manual/idle trigger only..."
    local service_dir="${HOME}/.config/systemd/user"
    mkdir -p "${service_dir}"
    create_gtklock_service "${service_dir}"

    systemctl --user daemon-reload || warn "Failed to reload systemd daemon."
    msg "Systemd services configured."
}

enable_systemd_services() {
    info "Enabling systemd services"
    # systemctl --user enable --now pipewire pipewire-pulse wireplumber
    # sudo systemctl enable --now bluetooth

    msg "Systemd services enabled"
}

create_gtklock_service() {
  local service_dir="$1"

  if ! verify_binary gtklock; then
    warn "gtklock binary not found, skipping service creation"
    return
  fi

  local gtklock_bin
  gtklock_bin="$(command -v gtklock)"

  cat > "${service_dir}/gtklock.service" <<EOF
[Unit]
Description=GTKLock Screen Locker
Documentation=man:gtklock(1)

[Service]
Type=simple
ExecStart=${gtklock_bin}
Restart=no
EOF

  info "Created: gtklock.service (manual trigger only)"
  info "Note: gtklock will NOT autostart. Trigger it via 'systemctl --user start gtklock'"
}

install_hypr_plugins() {
    info "Installing hyprland plugins"
    if hyprpm update; then
        msg "Updated successfully"
    else
        fatal "Hyprpm failed to update"
    fi

    local output status
    set +e
    output=$(hyprpm add https://github.com/hyprwm/hyprland-plugins 2>&1)
    status=$?
    set -e

    if [[ $status -eq 0 ]]; then
        msg "Repo added successfully."
    elif echo "$output" | grep -qi "already installed"; then
        msg "Repo already installed, skipping."
    else
        fatal "Failed to install repo"
    fi

    info "Enabling plugins"
    if hyprpm enable hyprexpo; then
        msg "Enabled hyprexpo plugin"
    else
        error "Failed to enable hyprexpo plugin"
    fi
}

configure_waytrogen() {
    local config_path="$HOME/.local/share/applications"
    
    if ! mkdir -p $config_path; then
        fatal "Failed to make user applications folder"
    fi

    cat > "${config_path}/waytrogen.desktop" <<EOF
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Terminal=false
Exec=waytrogen -e $HOME/.config/scripts/theme/theme-sync.sh
Name=Waytrogen
Icon=waytrogen
EOF
}

install_flatpak_apps() {
    info "Installing Flatpak apps"

    local flathub_repo="https://flathub.org/repo/flathub.flatpakrepo"

    # Add Flathub repo if not already added
    if sudo flatpak remote-add --if-not-exists flathub "$flathub_repo"; then
        msg "Installed Flathub repo successfully"
    else
        fatal "Failed to install Flathub repo to Flatpak"
    fi

    # Install each app from the list
    for app in "${FLATPAK_APPS[@]}"; do
        if flatpak install -y --or-update flathub "$app"; then
            msg "Installed $app successfully"
        else
            error "Failed to install $app, continuing with next app"
        fi
    done

    msg "Installed all Flatpak apps"
}


main() {
    info "Pre-flight system checks"
    check_not_root
    check_sudo
    msg "System validated and prerequisities checked"

    info "System update"
    update_system
    msg "System packages updated"

    info "Installing base development tools"
    install_base_tools
    msg "Base development tools installed (git, base-devel, curl)"

    info "Installing AUR package helper yay"
    install_yay
    msg "Installed yay"

    info "Installing official repository packages"
    install_pacman_packages
    msg "Official packages installed (wayland, waybar, fish, display drivers etc.)"

    info "Installing AUR packages"
    install_aur_packages
    msg "AUR packages installed"

    info "Installing GTK themes"
    install_gtk_themes
    msg "GTK themes installed (Colloid, Rose-pine, Osaka)"

    info "Installing icon themes"
    install_icon_themes
    msg "Icon themes installed (Colloid icons)"

    info "Cloning dotfiles repository"
    clone_or_update_dotfiles
    msg "Dotfiles repo cloned from ${DOTFILES_REPO}"

    info "Installing fonts"
    install_fonts
    msg "Fonts installed"

    info "Installing Wallpapers"
    install_wallpapers
    msg "Wallpapers installed to ~/Pictures/Wallpapers"

    info "Configuring system services"
    create_systemd_services
    enable_systemd_services
    msg "Systemd services configured"

    cp -f ~/.config/bash/bashrc ~/.bashrc
    source ~/.bashrc

    info "Installing hyprland plugins"
    install_hypr_plugins
    msg "Installed hyprland plugins successfully"

    info "Configure Waytrogen"
    configure_waytrogen
    msg "Configured Waytrogen successfully"

    info "Install flatpak apps"
    install_flatpak_apps
    msg "Installed flatpak apps successfully"

    info "Refreshing wallpaper and themes"
    waytrogen -r
    ~/.config/scripts/theme/theme-sync.sh
    msg "Refreshed wallpaper and themes successfully"

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
}

trap 'cleanup_on_error ${LINENO}' ERR
trap 'cleanup_on_exit' EXIT INT TERM

main
