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
    "starship.toml|catppuccin_mocha|catppuccin_latte" \
    "$HOME/.gitconfig|Catppuccin-mocha|Catppuccin-latte" \
    "atuin/config.toml|catppuccin-mocha-mauve|catppuccin-latte-mauve" \
    "zellij/config.kdl|catppuccin-mocha|catppuccin-latte" \
    "btop/btop.conf|catppuccin_mocha|catppuccin_latte" \
    "k9s/config.yaml|catppuccin-mocha|catppuccin-latte"

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
for pair in "bottom|bottom.toml" "eza|theme.yml" "yazi|theme.toml" "gh-dash|config.yml"
    set -l p (string split '|' $pair)
    set -l dir "$dotfiles/$p[1]"
    if test -d "$dir"
        set -l base (string replace -r '\.[^.]+$' '' $p[2])
        set -l ext (string replace -r '^[^.]*' '' $p[2])
        ln -sf "$base-$mode$ext" "$dir/$p[2]"
    end
end

# --- Runtime reloads ---

# Tmux: update flavor in config and reload catppuccin plugin
if type -q tmux; and tmux list-sessions >/dev/null 2>&1
    set -l flavor (test "$mode" = light && echo latte || echo mocha)
    set -l old_flavor (test "$mode" = light && echo mocha || echo latte)
    _sed_i "s/@catppuccin_flavor \"$old_flavor\"/@catppuccin_flavor \"$flavor\"/" "$dotfiles/tmux/tmux.conf"
    
    # Clear all catppuccin theme variables (they use -ogq so won't update otherwise)
    for var in (tmux show -g 2>/dev/null | grep -oE '^@(thm_|catppuccin_|_ctp_)[^ ]+')
        tmux set -gu $var 2>/dev/null
    end
    
    # Source tmux.conf FIRST so user options (@catppuccin_window_status_style etc.)
    # are set before the plugin reads them via -ogq
    tmux source-file "$dotfiles/tmux/tmux.conf" 2>/dev/null
    
    # Then re-source the catppuccin plugin to apply the new flavor
    set -l ctp_dir "$dotfiles/tmux/plugins/tmux"
    if test -d "$ctp_dir"
        tmux source-file "$ctp_dir/catppuccin_options_tmux.conf" 2>/dev/null
        tmux source-file "$ctp_dir/catppuccin_tmux.conf" 2>/dev/null
    end
    # Source tmux.conf again so post-catppuccin overrides apply
    tmux source-file "$dotfiles/tmux/tmux.conf" 2>/dev/null
end

# Neovim: update background on all running instances
if type -q nvim
    set -l bg (test "$mode" = light && echo light || echo dark)
    for sock in (find /var/folders /tmp -path "*/nvim.*/nvim.*" -type s 2>/dev/null)
        nvim --server "$sock" --remote-send "<Cmd>set background=$bg<CR>" 2>/dev/null
    end
end

# Fish: update universal variable (propagates to all running shells)
set -U THEME_MODE "$mode"

echo "Theme switched to $mode"
