#!/usr/bin/env fish
# switch-theme.fish — Switch all dotfiles tools between light and dark themes.
#
# Usage: switch-theme.fish light|dark
#
# This script is idempotent — calling it with the current mode is a no-op.
# Called by the macOS theme-watcher daemon or manually.

set -l mode $argv[1]

if test "$mode" != light -a "$mode" != dark
    echo "Usage: switch-theme.fish light|dark" >&2
    exit 1
end

# State file
set -l state_file "$HOME/.config/theme-mode"

# Check if mode has changed
if test -f "$state_file"
    set -l current (cat "$state_file")
    if test "$current" = "$mode"
        exit 0
    end
end

# Write new mode
mkdir -p "$HOME/.config"
echo "$mode" > "$state_file"

# Dotfiles config location (symlinked from repo)
set -l dotfiles "$HOME/.config"

# Helper: portable sed in-place (follows symlinks)
function _sed_i
    set -l file $argv[-1]
    set -l sed_args $argv[1..-2]
    # Resolve symlinks so sed -i works on macOS
    if test -L "$file"
        set file (realpath "$file")
    end
    if test (uname) = Darwin
        sed -i '' $sed_args "$file"
    else
        sed -i $sed_args "$file"
    end
end

# --- Sed-based config updates ---

# Starship: switch palette
if test "$mode" = light
    _sed_i 's/palette = "catppuccin_mocha"/palette = "catppuccin_latte"/' "$dotfiles/starship.toml"
else
    _sed_i 's/palette = "catppuccin_latte"/palette = "catppuccin_mocha"/' "$dotfiles/starship.toml"
end

# Gitconfig: switch delta theme
if test "$mode" = light
    _sed_i 's/Catppuccin-mocha/Catppuccin-latte/g' "$HOME/.gitconfig"
else
    _sed_i 's/Catppuccin-latte/Catppuccin-mocha/g' "$HOME/.gitconfig"
end

# Atuin: switch theme
if test "$mode" = light
    _sed_i 's/catppuccin-mocha-mauve/catppuccin-latte-mauve/' "$dotfiles/atuin/config.toml"
else
    _sed_i 's/catppuccin-latte-mauve/catppuccin-mocha-mauve/' "$dotfiles/atuin/config.toml"
end

# Zellij: switch theme
if test "$mode" = light
    _sed_i 's/theme "catppuccin-mocha"/theme "catppuccin-latte"/' "$dotfiles/zellij/config.kdl"
else
    _sed_i 's/theme "catppuccin-latte"/theme "catppuccin-mocha"/' "$dotfiles/zellij/config.kdl"
end

# Btop: switch theme
if test "$mode" = light
    _sed_i 's/catppuccin_mocha/catppuccin_latte/g' "$dotfiles/btop/btop.conf"
else
    _sed_i 's/catppuccin_latte/catppuccin_mocha/g' "$dotfiles/btop/btop.conf"
end

# K9s: switch skin
if test "$mode" = light
    _sed_i 's/skin: catppuccin-mocha/skin: catppuccin-latte/' "$dotfiles/k9s/config.yaml"
else
    _sed_i 's/skin: catppuccin-latte/skin: catppuccin-mocha/' "$dotfiles/k9s/config.yaml"
end

# --- Symlink-based config updates ---

# Bottom
if test -d "$dotfiles/bottom"
    if test "$mode" = light
        ln -sf bottom-light.toml "$dotfiles/bottom/bottom.toml"
    else
        ln -sf bottom-dark.toml "$dotfiles/bottom/bottom.toml"
    end
end

# Eza
if test -d "$dotfiles/eza"
    if test "$mode" = light
        ln -sf theme-light.yml "$dotfiles/eza/theme.yml"
    else
        ln -sf theme-dark.yml "$dotfiles/eza/theme.yml"
    end
end

# Yazi
if test -d "$dotfiles/yazi"
    if test "$mode" = light
        ln -sf theme-light.toml "$dotfiles/yazi/theme.toml"
    else
        ln -sf theme-dark.toml "$dotfiles/yazi/theme.toml"
    end
end

# gh-dash
if test -d "$dotfiles/gh-dash"
    if test "$mode" = light
        ln -sf config-light.yml "$dotfiles/gh-dash/config.yml"
    else
        ln -sf config-dark.yml "$dotfiles/gh-dash/config.yml"
    end
end

# --- Runtime reloads ---

# Tmux: set flavor and reload
if type -q tmux; and tmux list-sessions >/dev/null 2>&1
    if test "$mode" = light
        tmux set -g @catppuccin_flavor "latte"
    else
        tmux set -g @catppuccin_flavor "mocha"
    end
    tmux source-file "$dotfiles/tmux/tmux.conf" 2>/dev/null
end

# Fish: update universal variable (propagates to all running shells)
set -U THEME_MODE "$mode"

echo "Theme switched to $mode"
