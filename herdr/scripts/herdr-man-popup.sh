#!/usr/bin/env bash
# Herdr equivalent of tmux's `bind m command-prompt "splitw 'exec man %%'"`.
#
# Herdr has no command-prompt primitive, so the prompt lives inside the popup
# that the keybinding opens. fzf is used for completion when available, exactly
# like the rest of these dotfiles prefer it.
set -uo pipefail

page="${1:-}"

if [ -z "$page" ]; then
    if command -v fzf >/dev/null 2>&1; then
        page=$(apropos . 2>/dev/null |
            fzf --prompt='man > ' --height=100% --reverse --no-multi |
            awk '{print $1}')
    fi
fi

if [ -z "$page" ]; then
    printf 'man: '
    IFS= read -r page || exit 0
fi

[ -z "$page" ] && exit 0

man "$page"
