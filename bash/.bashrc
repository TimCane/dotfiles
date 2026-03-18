# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ── ble.sh (Bash Line Editor) — must be sourced early ──
if [[ -f "$HOME/.local/share/blesh/ble.sh" ]]; then
    source "$HOME/.local/share/blesh/ble.sh" --noattach
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# ── Starship prompt ──
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
export PATH="$HOME/.local/bin:$PATH"
export SUDO_ASKPASS="$HOME/.local/bin/sudo-askpass"

# Fastfetch on terminal open
if command -v fastfetch &>/dev/null; then
    fastfetch
fi

# Claude Code in tmux at /
alias cc='cd / && tmux new-session -A -s claude "claude --dangerously-skip-permissions"'

# ── fzf ──
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"

    # Gruvbox Dark theme
    export FZF_DEFAULT_OPTS="
      --color=bg+:#3c3836,bg:#282828,spinner:#fb4934,hl:#fabd2f
      --color=fg:#ebdbb2,header:#8ec07c,info:#83a598,pointer:#fe8019
      --color=marker:#b8bb26,fg+:#ebdbb2,prompt:#fb4934,hl+:#fabd2f
      --border --height=40% --layout=reverse --info=inline
    "
fi

# ── Modern CLI aliases ──
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first'
    alias lt='eza -la --icons --tree --level=2'
fi
if command -v bat &>/dev/null; then
    alias cat='bat --style=plain'
    alias catn='bat'
fi

# ── Environment ──
export BAT_THEME="gruvbox-dark"

# ── ble.sh attach (must be at the end of .bashrc) ──
if [[ ${BLE_VERSION-} ]]; then
    # Autosuggestion colour — Gruvbox dark grey
    ble-face -s auto_complete fg=#928374
    ble-bind -f C-f auto_complete/insert

    [[ ! ${BLE_ATTACHED-} ]] && ble-attach
fi
