#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/timcane/dotfiles"
DOTFILES_DIR="$HOME/.dotfiles"

bootstrap() {
  echo "[*] Bootstrapping..."
  sudo pacman -S --needed --noconfirm git base-devel

  if [ ! -d "$DOTFILES_DIR" ]; then
    git clone "$REPO_URL" "$DOTFILES_DIR"
  fi

  echo "[*] Restarting script from $DOTFILES_DIR"
  cd "$DOTFILES_DIR"
  exec bash install.sh  # replace current process with real installer
}

# If we’re not inside ~/.dotfiles, bootstrap first
if [[ "$PWD" != "$DOTFILES_DIR" ]]; then
  bootstrap
fi

echo "[*] Installing base packages..."
sudo pacman -S --needed firefox github-cli unzip wget --noconfirm

echo "[*] Setting up yay (AUR helper)..."
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  pushd /tmp/yay
  makepkg -si --noconfirm
  popd
  mkdir -p ~/AUR
  mv /tmp/yay ~/AUR/
fi

echo "[*] Installing stow..."
yay -S --needed stow --noconfirm

echo "[*] Stowing dotfiles..."

# Stow configurations
stow bash --adopt *
stow git --adopt *
stow alacritty --adopt *
stow i3 --adopt *
stow lxqt --adopt *
stow openbox --adopt *
stow picom --adopt *
stow polybar --adopt *
stow rofi --adopt *
stow wallpapers --adopt *
stow fastfetch --adopt *

echo "[*] Creating system-wide symlink for LXQt theme..."
if [ -d "$HOME/.themes/catppuccin-mocha/lxqt" ]; then
  echo "[*] Creating system-wide symlink for LXQt theme..."
  sudo mkdir -p /usr/share/lxqt/themes/
  if [ ! -L "/usr/share/lxqt/themes/catppuccin-mocha" ]; then
    sudo ln -sfn "$HOME/.themes/catppuccin-mocha/lxqt" "/usr/share/lxqt/themes/catppuccin-mocha"
  fi
fi

git restore . 

echo "[*] Installing packages from AUR..."
yay -S --needed alacritty i3-wm picom polybar rofi feh visual-studio-code-bin nano i3lock-color --noconfirm

echo "[*] All done! 🎉"
