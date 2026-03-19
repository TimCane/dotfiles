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

dim='\033[2m'

info()  { echo -e "${green}[+]${reset} $*"; }
warn()  { echo -e "${yellow}[!]${reset} $*"; }
error() { echo -e "${red}[x]${reset} $*"; }

# Run a command with rolling dimmed output (last 5 lines), cleared on finish.
# On failure the last 20 lines are shown for debugging.
run() {
    local max=5
    local tmp
    tmp="$(mktemp)"
    local cols
    cols="$(tput cols 2>/dev/null || echo 80)"

    "$@" &> "$tmp" &
    local pid=$!

    local on_screen=0 prev_total=0
    while kill -0 "$pid" 2>/dev/null; do
        local total
        total="$(wc -l < "$tmp")"
        if ((total != prev_total)); then
            local show=$((total < max ? total : max))
            ((on_screen > 0)) && printf '\033[%dA' "$on_screen"
            tail -n "$show" "$tmp" | while IFS= read -r l; do
                printf "${dim}  \033[K%.*s${reset}\n" "$((cols - 4))" "$l"
            done
            on_screen=$show
            prev_total=$total
        fi
        sleep 0.1
    done

    wait "$pid"
    local rc=$?

    # Final redraw in case output arrived after last poll
    local total
    total="$(wc -l < "$tmp")"
    if ((total != prev_total)); then
        local show=$((total < max ? total : max))
        ((on_screen > 0)) && printf '\033[%dA' "$on_screen"
        tail -n "$show" "$tmp" | while IFS= read -r l; do
            printf "${dim}  \033[K%.*s${reset}\n" "$((cols - 4))" "$l"
        done
        on_screen=$show
    fi

    # Clear rolling area
    if ((on_screen > 0)); then
        printf '\033[%dA' "$on_screen"
        for ((i = 0; i < on_screen; i++)); do printf '\033[K\n'; done
        printf '\033[%dA' "$on_screen"
    fi

    # On failure, dump last 20 lines for debugging
    if ((rc != 0)); then
        tail -n 20 "$tmp" | while IFS= read -r l; do
            printf "${dim}  %s${reset}\n" "$l"
        done
    fi

    rm -f "$tmp"
    return "$rc"
}

# ── Bootstrap essentials (needed before anything else) ──
bootstrap() {
    info "Installing bootstrap dependencies..."
    run sudo apt update
    run sudo apt install -y curl wget gnupg unzip
}

# ── Third-party repositories ──
setup_repos() {
    # VS Code repository
    if [[ ! -f /etc/apt/sources.list.d/vscode.sources ]]; then
        info "Adding VS Code repository..."
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
        cat <<'EOF' | sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
    else
        info "VS Code repository already configured"
    fi
}

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
        fastfetch
        glow
        gh
        code
        plymouth plymouth-themes
        ufw
        apparmor-utils
        shim-signed grub-efi-amd64-signed sbsigntool mokutil
        imagemagick
        jq
        pipx
    )

    local audio=(pipewire pipewire-pulse wireplumber pavucontrol)
    local filemanager=(thunar tumbler ffmpegthumbnailer)
    local media=(nsxiv mpv)
    local archives=(file-roller p7zip-full unrar)
    local disktools=(gnome-disk-utility baobab)
    local fonts=(fonts-noto-color-emoji fonts-noto-cjk fonts-liberation)
    local desktop=(xdg-desktop-portal-gtk gnome-keyring libsecret-tools)
    local power=(tlp)
    local maintenance=(unattended-upgrades)
    local vpn=(openvpn)
    local terminal=(bash-completion eza bat)

    info "Updating package lists..."
    run sudo apt update
    info "Installing apt packages..."
    run sudo apt install -y "${core[@]}" "${polybar[@]}" "${theming[@]}" "${utils[@]}" \
        "${audio[@]}" "${filemanager[@]}" "${media[@]}" "${archives[@]}" \
        "${disktools[@]}" "${fonts[@]}" "${desktop[@]}" "${power[@]}" \
        "${maintenance[@]}" "${vpn[@]}" "${terminal[@]}"

    # Packages not in default repos — install manually if missing
    install_if_missing "greenclip" install_greenclip
    install_if_missing "flashfocus" install_flashfocus
    install_if_missing "betterlockscreen" install_betterlockscreen
    install_if_missing "yazi" install_yazi
    install_if_missing "pass-cli" install_proton_pass
    install_if_missing "protonvpn-cli" install_protonvpn
    install_if_missing "delta" install_delta
    install_if_missing "starship" install_starship
    install_if_missing "ble" install_blesh
}

install_if_missing() {
    local cmd="$1" installer="$2"
    if ! command -v "$cmd" &>/dev/null; then
        warn "$cmd not found, installing..."
        run "$installer" || error "Failed to install $cmd — install it manually"
    else
        info "$cmd already installed"
    fi
}

install_greenclip() {
    local version="v4.2"
    local expected_sha256="80b189fc9ce2e0a56e33be642875f5c3fb53647465f8024a541621307a6a290f"
    local url="https://github.com/erebe/greenclip/releases/download/${version}/greenclip"
    wget -q "$url" -O /tmp/greenclip
    local actual_sha256
    actual_sha256="$(sha256sum /tmp/greenclip | awk '{print $1}')"
    if [[ "$actual_sha256" != "$expected_sha256" ]]; then
        error "greenclip checksum mismatch! Expected $expected_sha256, got $actual_sha256"
        rm -f /tmp/greenclip
        return 1
    fi
    chmod +x /tmp/greenclip
    sudo mv /tmp/greenclip /usr/local/bin/
}

install_flashfocus() {
    pipx install flashfocus
}

install_betterlockscreen() {
    local url="https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh"
    wget -q "$url" -O /tmp/bls-install.sh
    chmod +x /tmp/bls-install.sh
    /tmp/bls-install.sh user
}

install_proton_pass() {
    info "Installing Proton Pass CLI..."
    curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
}

install_yazi() {
    info "Installing yazi from GitHub release..."
    local version
    version="$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest | grep -Po '"tag_name": "\K[^"]*')"
    local tarball="/tmp/yazi.zip"
    curl -fsSL "https://github.com/sxyazi/yazi/releases/download/${version}/yazi-x86_64-unknown-linux-gnu.zip" -o "$tarball"
    unzip -o "$tarball" -d /tmp/yazi
    sudo mv /tmp/yazi/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
    sudo mv /tmp/yazi/yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/
    rm -rf "$tarball" /tmp/yazi
}

install_protonvpn() {
    info "Installing ProtonVPN CLI..."
    local deb="/tmp/protonvpn-stable-release.deb"
    wget -q "https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.6_all.deb" -O "$deb"
    sudo dpkg -i "$deb"
    # Refresh the repo signing key (the bundled .deb key can go stale)
    curl -fsSL https://repo.protonvpn.com/debian/public_key.asc \
        | sudo gpg --dearmor --yes -o /usr/share/keyrings/protonvpn-stable-archive-keyring.gpg
    sudo apt update
    sudo apt install -y protonvpn-cli
    rm -f "$deb"
}

install_delta() {
    info "Installing git-delta..."
    local version
    version="$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest | grep -Po '"tag_name": "\K[^"]*')"
    local deb="/tmp/git-delta.deb"
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${version}/git-delta_${version}_amd64.deb" -o "$deb"
    sudo dpkg -i "$deb"
    rm -f "$deb"
}

install_starship() {
    info "Installing Starship prompt..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
}

install_blesh() {
    info "Installing ble.sh (Bash Line Editor)..."
    local version
    version="$(curl -fsSL https://api.github.com/repos/akinomyoga/ble.sh/releases/latest | grep -Po '"tag_name": "\K[^"]*')"
    local tarball="/tmp/blesh.tar.xz"
    curl -fsSL "https://github.com/akinomyoga/ble.sh/releases/download/${version}/ble-${version}.tar.xz" -o "$tarball"
    mkdir -p "$HOME/.local/share/blesh"
    tar -xf "$tarball" -C "$HOME/.local/share/blesh" --strip-components=1
    rm -f "$tarball"
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
    _install_nerd_font() {
        local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        wget -q "$url" -O /tmp/JetBrainsMono.tar.xz
        tar -xf /tmp/JetBrainsMono.tar.xz -C "$1"
        fc-cache -f
        rm /tmp/JetBrainsMono.tar.xz
    }
    run _install_nerd_font "$font_dir"
}

# ── GTK Theme ──
install_gruvbox_gtk() {
    if [[ -d /usr/share/themes/Gruvbox-Dark ]] || [[ -d "$HOME/.themes/Gruvbox-Dark" ]]; then
        info "Gruvbox GTK theme already installed"
        return
    fi

    info "Installing Gruvbox GTK theme..."
    mkdir -p "$HOME/.themes"
    rm -rf /tmp/gruvbox-gtk
    git clone --depth 1 https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/gruvbox-gtk
    bash /tmp/gruvbox-gtk/themes/install.sh -c Dark -t default
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
    _install_bibata() {
        local url="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz"
        wget -q "$url" -O /tmp/bibata.tar.xz
        tar -xf /tmp/bibata.tar.xz -C "$HOME/.icons/"
        rm /tmp/bibata.tar.xz
    }
    run _install_bibata
}

# ── LightDM ──
configure_lightdm() {
    info "Configuring LightDM greeter..."
    sudo cp "$DOTFILES_DIR/etc/lightdm/lightdm.conf" /etc/lightdm/lightdm.conf
    sudo cp "$DOTFILES_DIR/etc/lightdm/lightdm-gtk-greeter.conf" /etc/lightdm/lightdm-gtk-greeter.conf
    sudo cp "$DOTFILES_DIR/etc/lightdm/lightdm-gtk-greeter.css" /etc/lightdm/lightdm-gtk-greeter.css
}

# ── Plymouth theme ──
configure_plymouth() {
    info "Installing Gruvbox Plymouth theme..."
    sudo cp -r "$DOTFILES_DIR/etc/plymouth/themes/gruvbox" /usr/share/plymouth/themes/
    sudo cp "$DOTFILES_DIR/etc/plymouth/plymouthd.conf" /etc/plymouth/plymouthd.conf
    run sudo update-initramfs -u || warn "Failed to update initramfs — run: sudo update-initramfs -u"
}

# ── Claude CLI ──
install_claude() {
    if command -v claude &>/dev/null; then
        info "Claude CLI already installed"
        return
    fi
    info "Installing Claude CLI..."
    run bash -c 'curl -fsSL https://cli.anthropic.com/install.sh | sh'
}

# ── Secure Boot ──
configure_secureboot() {
    info "Configuring Secure Boot support..."

    # Verify shim + signed GRUB are installed
    if ! dpkg -l shim-signed grub-efi-amd64-signed &>/dev/null; then
        error "shim-signed or grub-efi-amd64-signed not installed — cannot configure Secure Boot"
        return 1
    fi

    # Reinstall GRUB through shim so the EFI boot entry points at shimx64.efi
    info "Installing GRUB with Secure Boot chain (shim → GRUB → kernel)..."
    sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi \
        --bootloader-id=debian --uefi-secure-boot
    sudo update-grub

    # Set up MOK signing for DKMS modules (e.g. NVIDIA, VirtualBox)
    if dkms status 2>/dev/null | grep -q .; then
        info "DKMS modules detected — setting up MOK signing..."
        configure_mok_signing
    else
        info "No DKMS modules found — MOK signing not needed (yet)"
        info "  If you install DKMS modules later (e.g. NVIDIA), re-run: configure_mok_signing"
    fi

    # Verify the boot chain
    if [[ -f /boot/efi/EFI/debian/shimx64.efi ]]; then
        info "Secure Boot chain verified: shimx64.efi present"
    else
        warn "shimx64.efi not found in /boot/efi/EFI/debian/ — check grub-install output"
    fi

    info "Secure Boot setup complete."
    info "  Enable Secure Boot in BIOS — both Windows and Linux will boot via the shim chain."
}

configure_mok_signing() {
    local mok_dir="/var/lib/shim-signed/mok"

    if [[ -f "$mok_dir/MOK.priv" && -f "$mok_dir/MOK.der" ]]; then
        info "MOK key pair already exists"
    else
        info "Generating MOK key pair..."
        sudo mkdir -p "$mok_dir"
        sudo openssl req -new -x509 -newkey rsa:2048 \
            -keyout "$mok_dir/MOK.priv" \
            -outform DER -out "$mok_dir/MOK.der" \
            -days 36500 -subj "/CN=$USER DKMS Signing Key/" -nodes
        sudo chmod 600 "$mok_dir/MOK.priv"
    fi

    # Enroll the key — prompts for a one-time password, then requires reboot
    if ! mokutil --test-key "$mok_dir/MOK.der" 2>/dev/null | grep -q "is already enrolled"; then
        info "Enrolling MOK key (you will set a one-time password, then confirm on next reboot)..."
        sudo mokutil --import "$mok_dir/MOK.der"
    else
        info "MOK key already enrolled"
    fi

    # Install DKMS signing helper
    info "Installing DKMS sign helper..."
    sudo cp "$DOTFILES_DIR/etc/dkms/sign_helper.sh" /etc/dkms/sign_helper.sh
    sudo chmod +x /etc/dkms/sign_helper.sh

    # Configure DKMS to use the signing helper
    if ! grep -q "sign_tool" /etc/dkms/framework.conf 2>/dev/null; then
        info "Configuring DKMS to auto-sign modules..."
        echo 'sign_tool="/etc/dkms/sign_helper.sh"' | sudo tee -a /etc/dkms/framework.conf > /dev/null
    else
        info "DKMS already configured to sign modules"
    fi

    # Re-sign any existing DKMS modules
    local modules
    modules="$(dkms status 2>/dev/null | awk -F'[,: ]+' '{print $1"/"$2}' | sort -u)"
    if [[ -n "$modules" ]]; then
        info "Re-building DKMS modules with signing..."
        while IFS= read -r mod; do
            local name="${mod%/*}" ver="${mod#*/}"
            info "  Rebuilding $name/$ver..."
            sudo dkms build "$name/$ver" 2>/dev/null || true
            sudo dkms install "$name/$ver" 2>/dev/null || true
        done <<< "$modules"
    fi
}

# ── Security hardening ──
harden_system() {
    info "Applying security hardening..."

    # Disable SSH (not needed — all dev is remote via VS Code)
    if systemctl is-enabled ssh &>/dev/null; then
        info "Disabling SSH service..."
        sudo systemctl stop ssh
        sudo systemctl disable ssh
    else
        info "SSH already disabled"
    fi

    # Install and configure UFW firewall
    if ! command -v ufw &>/dev/null; then
        info "Installing UFW..."
        sudo apt install -y ufw
    fi
    if ! sudo ufw status | grep -q "Status: active"; then
        info "Configuring UFW (deny incoming, allow outgoing)..."
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw --force enable
    else
        info "UFW already active"
    fi

    # Configure sudoers with global credential caching
    local sudoers_file="/etc/sudoers.d/$USER"
    info "Configuring sudoers (global, 30-min timeout)..."
    printf 'Defaults:%s timestamp_type=global\nDefaults:%s timestamp_timeout=30\n%s ALL=(ALL:ALL) ALL\n' \
        "$USER" "$USER" "$USER" | sudo tee "$sudoers_file" > /dev/null

    # Enable AppArmor and enforce only Debian's default enforced profiles
    if ! systemctl is-enabled apparmor &>/dev/null; then
        sudo systemctl enable apparmor
        sudo systemctl start apparmor
    fi
    if command -v aa-enforce &>/dev/null; then
        info "Enforcing default AppArmor profiles..."
        local enforce_profiles=(
            /etc/apparmor.d/usr.bin.man
            /etc/apparmor.d/usr.sbin.cupsd
            /etc/apparmor.d/usr.sbin.cups-browsed
            /etc/apparmor.d/nvidia_modprobe
            /etc/apparmor.d/lsb_release
            /etc/apparmor.d/unix-chkpwd
            /etc/apparmor.d/unprivileged_userns
        )
        for profile in "${enforce_profiles[@]}"; do
            [[ -f "$profile" ]] && sudo aa-enforce "$profile" 2>/dev/null || true
        done
    else
        warn "apparmor-utils not installed — install it and run: sudo aa-enforce <profiles>"
    fi

    # Install kernel network hardening sysctl config
    info "Installing sysctl hardening config..."
    sudo cp "$DOTFILES_DIR/etc/sysctl.d/99-security.conf" /etc/sysctl.d/99-security.conf
    sudo sysctl --system > /dev/null 2>&1
}

# ── Stow packages ──
stow_packages() {
    info "Stowing dotfiles..."
    cd "$DOTFILES_DIR"

    local packages=(
        i3 alacritty polybar rofi i3blocks picom dunst
        bash tmux scripts x11 gtk xdg flameshot fzf code git
        greenclip glow qt5ct fastfetch fontconfig starship readline
    )

    # Ensure target dirs exist
    mkdir -p "$HOME/.config" "$HOME/.local/bin"

    for pkg in "${packages[@]}"; do
        if [[ -d "$pkg" ]]; then
            info "  Stowing $pkg..."
            run stow -v --target="$HOME" --restow "$pkg" || true
        fi
    done
}

# ── VS Code extensions ──
install_vscode_extensions() {
    if ! command -v code &>/dev/null; then
        warn "VS Code not found — skipping extension install"
        return
    fi

    info "Installing VS Code extensions..."
    local extensions=(
        jdinhlife.gruvbox
        ms-vscode-remote.vscode-remote-extensionpack
    )

    for ext in "${extensions[@]}"; do
        code --install-extension "$ext" --force 2>/dev/null || warn "Failed to install $ext"
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
    info "  3. Enable Secure Boot in BIOS — the shim chain is installed"
    if dkms status 2>/dev/null | grep -q .; then
        info "  4. Reboot and enroll MOK key when prompted (use the password you set)"
    fi
}

# ── Power management ──
configure_power() {
    info "Configuring power management..."
    sudo mkdir -p /etc/systemd/logind.conf.d
    sudo cp "$DOTFILES_DIR/etc/systemd/logind.conf.d/lid.conf" /etc/systemd/logind.conf.d/lid.conf

    # Enable TLP on laptops
    if [[ -d /sys/class/power_supply/BAT0 ]] && command -v tlp &>/dev/null; then
        info "Laptop detected — enabling TLP..."
        sudo systemctl enable tlp
        sudo systemctl start tlp
    fi
}

# ── Unattended upgrades ──
configure_unattended_upgrades() {
    info "Configuring unattended upgrades..."
    sudo cp "$DOTFILES_DIR/etc/apt/apt.conf.d/50unattended-upgrades" /etc/apt/apt.conf.d/50unattended-upgrades
    sudo cp "$DOTFILES_DIR/etc/apt/apt.conf.d/20auto-upgrades" /etc/apt/apt.conf.d/20auto-upgrades
}

# ── Crash diagnostics ──
configure_diagnostics() {
    info "Configuring crash diagnostics..."

    sudo mkdir -p /etc/systemd/coredump.conf.d
    sudo cp "$DOTFILES_DIR/etc/systemd/coredump.conf.d/custom.conf" /etc/systemd/coredump.conf.d/custom.conf

    sudo mkdir -p /etc/systemd/journald.conf.d
    sudo cp "$DOTFILES_DIR/etc/systemd/journald.conf.d/persistent.conf" /etc/systemd/journald.conf.d/persistent.conf

    sudo mkdir -p /var/log/journal
    sudo systemd-tmpfiles --create --prefix /var/log/journal 2>/dev/null || true
    sudo systemctl restart systemd-journald
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

    bootstrap
    setup_repos
    install_packages
    install_fonts
    install_gruvbox_gtk
    install_bibata_cursor
    stow_packages
    configure_lightdm
    configure_plymouth
    install_vscode_extensions
    install_claude
    generate_wallpaper
    configure_secureboot
    harden_system
    configure_power
    configure_unattended_upgrades
    configure_diagnostics
    post_install
}

main "$@"
