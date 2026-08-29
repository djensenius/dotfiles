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
# Each entry: file|dark-pattern|light-pattern
set -l sed_swaps \
    "$HOME/.gitconfig|Catppuccin-mocha|Catppuccin-latte" \
    "atuin/config.toml|catppuccin-mocha-mauve|catppuccin-latte-mauve" \
    "zellij/config.kdl|catppuccin-mocha|catppuccin-latte" \
    "btop/btop.conf|catppuccin_mocha|catppuccin_latte" \
    "k9s/config.yaml|catppuccin-mocha|catppuccin-latte"

# Starship: only replace on the "palette = " line to avoid renaming palette definitions
if test "$mode" = light
    _sed_i '/^palette = /s/catppuccin_mocha/catppuccin_latte/' "$dotfiles/starship.toml"
else
    _sed_i '/^palette = /s/catppuccin_latte/catppuccin_mocha/' "$dotfiles/starship.toml"
end

for swap in $sed_swaps
    set -l p (string split '|' $swap)
    set -l file (string match -rq '^/' -- $p[1] && echo $p[1] || echo "$dotfiles/$p[1]")
    if test "$mode" = light
        _sed_i "s/$p[2]/$p[3]/g" "$file"
    else
        _sed_i "s/$p[3]/$p[2]/g" "$file"
    end
end

# --- Symlink-based config updates ---
# Each entry: directory|filename (dark/light variants use -dark/-light suffix)
for pair in "bottom|bottom.toml" "eza|theme.yml" "gh-dash|config.yml"
    set -l p (string split '|' $pair)
    set -l dir "$dotfiles/$p[1]"
    if test -d "$dir"
        set -l base (string replace -r '\.[^.]+$' '' $p[2])
        set -l ext (string replace -r '^[^.]*' '' $p[2])
        ln -sf "$base-$mode$ext" "$dir/$p[2]"
    end
end

# --- Runtime reloads ---

# Tmux: handled natively by client-dark-theme/client-light-theme hooks in tmux.conf

# Neovim: update background on all running instances
if type -q nvim
    set -l bg (test "$mode" = light && echo light || echo dark)
    for sock in (find /var/folders /tmp -path "*/nvim.*/nvim.*" -type s 2>/dev/null)
        nvim --server "$sock" --remote-send "<Cmd>set background=$bg<CR>" 2>/dev/null
    end
end

# Fish: theme detection handled natively by fish 4.x via $fish_terminal_color_theme

echo "Theme switched to $mode"
