#!/bin/bash
set -euo pipefail

# Dotfiles installer — Debian/Ubuntu + i3 Gruvbox Dark setup
# Usage: ./install.sh [--stow-only]

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
STOW_ONLY=false

if [[ "${1:-}" == "--stow-only" ]]; then
    STOW_ONLY=true
fi

# ── Colors ──
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
reset='\033[0m'

info()  { echo -e "${green}[+]${reset} $*"; }
warn()  { echo -e "${yellow}[!]${reset} $*"; }
error() { echo -e "${red}[x]${reset} $*"; }

# ── Package installation ──
install_packages() {
    info "Installing packages..."

    # Core
    local core=(
        i3-wm i3lock i3status i3blocks
        stow
        alacritty
        rofi
        picom
        dunst
        feh
        flameshot xclip xdotool
        fzf
        zathura
        brightnessctl
        playerctl
        tmux
        udiskie
        lxpolkit
        network-manager-gnome
        blueman
    )

    # Polybar
    local polybar=(polybar)

    # Theming
    local theming=(
        papirus-icon-theme
        lxappearance
        qt5ct
    )

    # Utilities
    local utils=(
        xss-lock
        autorandr
        gammastep
    )

    sudo apt update
    sudo apt install -y "${core[@]}" "${polybar[@]}" "${theming[@]}" "${utils[@]}"

    # Packages not in default repos — install manually if missing
    install_if_missing "greenclip" install_greenclip
    install_if_missing "flashfocus" install_flashfocus
    install_if_missing "betterlockscreen" install_betterlockscreen
    install_if_missing "yazi" install_yazi
}

install_if_missing() {
    local cmd="$1" installer="$2"
    if ! command -v "$cmd" &>/dev/null; then
        warn "$cmd not found, attempting install..."
        "$installer" || error "Failed to install $cmd — install it manually"
    else
        info "$cmd already installed"
    fi
}

install_greenclip() {
    local url="https://github.com/erebe/greenclip/releases/latest/download/greenclip"
    wget -q "$url" -O /tmp/greenclip
    chmod +x /tmp/greenclip
    sudo mv /tmp/greenclip /usr/local/bin/
}

install_flashfocus() {
    pip install --user flashfocus 2>/dev/null || pipx install flashfocus
}

install_betterlockscreen() {
    local url="https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh"
    wget -q "$url" -O /tmp/bls-install.sh
    chmod +x /tmp/bls-install.sh
    /tmp/bls-install.sh user
}

install_yazi() {
    # Check for cargo, else suggest manual install
    if command -v cargo &>/dev/null; then
        cargo install --locked yazi-fm yazi-cli
    else
        error "Install yazi manually: https://yazi-rs.github.io/docs/installation"
        return 1
    fi
}

# ── Fonts ──
install_fonts() {
    local font_dir="$HOME/.local/share/fonts"
    if ls "$font_dir"/JetBrainsMonoNerdFont-Regular.ttf &>/dev/null; then
        info "JetBrainsMono Nerd Font already installed"
        return
    fi

    info "Installing JetBrainsMono Nerd Font..."
    mkdir -p "$font_dir"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    wget -q "$url" -O /tmp/JetBrainsMono.tar.xz
    tar -xf /tmp/JetBrainsMono.tar.xz -C "$font_dir"
    fc-cache -f
    rm /tmp/JetBrainsMono.tar.xz
}

# ── GTK Theme ──
install_gruvbox_gtk() {
    if [[ -d /usr/share/themes/Gruvbox-Dark ]] || [[ -d "$HOME/.themes/Gruvbox-Dark" ]]; then
        info "Gruvbox GTK theme already installed"
        return
    fi

    info "Installing Gruvbox GTK theme..."
    mkdir -p "$HOME/.themes"
    git clone --depth 1 https://github.com/Fausto-Korpsvansen/Gruvbox-GTK-Theme.git /tmp/gruvbox-gtk
    cp -r /tmp/gruvbox-gtk/themes/Gruvbox-Dark* "$HOME/.themes/"
    rm -rf /tmp/gruvbox-gtk
}

# ── Cursor theme ──
install_bibata_cursor() {
    if [[ -d /usr/share/icons/Bibata-Modern-Classic ]] || [[ -d "$HOME/.icons/Bibata-Modern-Classic" ]]; then
        info "Bibata cursor theme already installed"
        return
    fi

    info "Installing Bibata cursor theme..."
    mkdir -p "$HOME/.icons"
    local url="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz"
    wget -q "$url" -O /tmp/bibata.tar.xz
    tar -xf /tmp/bibata.tar.xz -C "$HOME/.icons/"
    rm /tmp/bibata.tar.xz
}

# ── Stow packages ──
stow_packages() {
    info "Stowing dotfiles..."
    cd "$DOTFILES_DIR"

    local packages=(
        i3 alacritty polybar rofi i3blocks picom dunst
        bash tmux scripts x11 gtk xdg flameshot fzf
    )

    # Ensure target dirs exist
    mkdir -p "$HOME/.config" "$HOME/.local/bin"

    for pkg in "${packages[@]}"; do
        if [[ -d "$pkg" ]]; then
            info "  Stowing $pkg..."
            stow -v --target="$HOME" --restow "$pkg" 2>&1 | grep -v "^$" || true
        fi
    done
}

# ── Wallpaper ──
generate_wallpaper() {
    local wp="$HOME/.config/i3/wallpaper.png"
    if [[ -f "$wp" ]]; then
        info "Wallpaper already exists"
        return
    fi

    info "Generating wallpaper..."
    if command -v python3 &>/dev/null; then
        python3 "$HOME/.config/i3/generate-wallpaper.py" || warn "Wallpaper generation failed — set one manually with feh"
    fi
}

# ── Post-install ──
post_install() {
    info "Running post-install steps..."

    # Update font cache
    fc-cache -f 2>/dev/null || true

    # Cache lock screen image
    if command -v betterlockscreen &>/dev/null && [[ -f "$HOME/.config/i3/wallpaper.png" ]]; then
        info "Caching lock screen image..."
        betterlockscreen -u "$HOME/.config/i3/wallpaper.png" || true
    fi

    info ""
    info "Done! Things to check:"
    info "  1. Set GTK theme with: lxappearance"
    info "  2. Log out and select i3 from your display manager"
}

# ── Main ──
main() {
    info "=== Dotfiles Installer ==="
    info "Dotfiles directory: $DOTFILES_DIR"
    echo ""

    if [[ "$STOW_ONLY" == true ]]; then
        stow_packages
        exit 0
    fi

    install_packages
    install_fonts
    install_gruvbox_gtk
    install_bibata_cursor
    stow_packages
    generate_wallpaper
    post_install
}

main "$@"
