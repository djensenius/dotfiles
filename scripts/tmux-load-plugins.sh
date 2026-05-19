#!/usr/bin/env sh
set -eu

finish() {
    status=$?

    if [ "$status" -eq 0 ]; then
        tmux set-option -g @tmux_plugins_loading "0" 2>/dev/null || true
    else
        tmux set-option -g @tmux_plugins_loading "failed" 2>/dev/null || true
    fi

    tmux refresh-client -S 2>/dev/null || true
}

trap finish EXIT

"$HOME/.config/tmux/plugins/tpm/tpm"

tmux source-file "$HOME/.config/tmux/post-tpm.conf"
tmux set-option -g status-style "bg=terminal"
tmux set-option -g mouse on
tmux set-window-option -g mode-keys vi

# Overrides that depend on Catppuccin plugin options must run after TPM.
tmux source-file "$HOME/.config/tmux/post-catppuccin.conf"
