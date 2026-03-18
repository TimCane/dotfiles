# Dotfiles — i3 Gruvbox Dark

Tiling desktop environment built on i3wm with a Gruvbox Dark color scheme.

## What's included

| Package | Config |
|---------|--------|
| **i3** | Window manager, gaps, keybindings |
| **Alacritty** | Terminal (Gruvbox colors, transparency) |
| **Polybar** | Status bar (workspaces, CPU, RAM, battery, volume, media) |
| **Rofi** | App launcher, window switcher, clipboard, power menu |
| **Picom** | Compositor (shadows, blur, rounded corners, fade) |
| **Dunst** | Notification daemon |
| **Tmux** | Terminal multiplexer |
| **GTK** | Gruvbox Dark theme, Papirus icons, Bibata cursor |

### Utilities

- **betterlockscreen** — lock screen with blurred wallpaper
- **greenclip** — clipboard manager (Mod+c)
- **flashfocus** — flash window on focus change
- **gammastep** — blue light filter
- **autorandr** — auto display configuration
- **yazi** — terminal file manager (Mod+n)
- **maim** — screenshots
- **playerctl** — media controls

## Quick start

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

This will:
1. Install all packages via apt (+ manual installs for greenclip, betterlockscreen, etc.)
2. Install JetBrainsMono Nerd Font
3. Install Gruvbox GTK theme and Bibata cursor
4. Symlink all configs via GNU Stow
5. Generate the wallpaper

### Stow only (no package installation)

If packages are already installed and you just want to link configs:

```bash
./install.sh --stow-only
```

### Manual stow

To stow/unstow individual packages:

```bash
cd ~/dotfiles
stow -t ~ i3          # link i3 config
stow -t ~ -D polybar  # unlink polybar config
stow -t ~ -R alacritty # re-link alacritty config
```

## Post-install checklist

- [ ] **Gammastep coordinates** — edit `~/.config/i3/config`, change `-l 51.5:-0.1` to your lat/lon
- [ ] **Battery device** — check `ls /sys/class/power_supply/` and update polybar `config.ini` if not `BAT0`/`ADP1`
- [ ] **GTK theme** — run `lxappearance` to verify Gruvbox Dark / Papirus / Bibata are selected
- [ ] **Lock screen** — run `betterlockscreen -u ~/.config/i3/wallpaper.png` to cache the image
- [ ] **Display manager** — log out and select "i3" from your session menu

## Key bindings

| Key | Action |
|-----|--------|
| `Mod+Return` | Terminal (Alacritty) |
| `Mod+d` / `Mod+Space` | App launcher (Rofi) |
| `Mod+q` | Kill window |
| `Mod+h/j/k/;` | Focus left/down/up/right |
| `Mod+Shift+h/j/k/;` | Move window |
| `Mod+f` | Fullscreen |
| `Mod+s/w/e` | Stacking/tabbed/split layout |
| `Mod+Shift+Space` | Toggle floating |
| `Mod+r` | Resize mode |
| `Mod+1-0` | Switch workspace |
| `Mod+Shift+1-0` | Move to workspace |
| `Mod+Tab` | Window switcher |
| `Mod+c` | Clipboard manager |
| `Mod+n` | File manager (yazi) |
| `Mod+l` | Lock screen |
| `Mod+x` | Power menu |
| `Mod+/` | Show all keybindings |
| `Mod+\`` | Scratchpad terminal |
| `Mod+m` | Set window mark |
| `Mod+'` | Go to marked window |
| `Print` | Screenshot (full) |
| `Shift+Print` | Screenshot (selection to clipboard) |
| `Mod+Print` | Screenshot (active window) |
| `Mod+Shift+c` | Reload i3 config |
| `Mod+Shift+r` | Restart i3 |

## Structure

```
dotfiles/
├── install.sh          # Full installer
├── README.md
├── i3/                 # i3wm config + wallpaper
├── alacritty/          # Terminal config
├── polybar/            # Status bar + scripts
├── rofi/               # Launcher config
├── i3blocks/           # Legacy status bar (backup)
├── picom/              # Compositor
├── dunst/              # Notifications
├── bash/               # .bashrc, .profile
├── tmux/               # .tmux.conf
├── scripts/            # ~/.local/bin scripts
├── x11/                # .xinitrc, .xprofile
└── gtk/                # GTK 2/3 theme settings
```

Each directory is a GNU Stow package. The internal structure mirrors `$HOME`, so stow creates the correct symlinks automatically.
