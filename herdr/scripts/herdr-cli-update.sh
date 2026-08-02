#!/usr/bin/env bash
set -uo pipefail

CACHE_DIR="${TMPDIR:-/tmp}/tmux-outdated-packages"
UPDATER="$HOME/.config/tmux/plugins/tmux-outdated-packages/scripts/show-popup.sh"

if [ ! -x "$UPDATER" ]; then
    printf 'cli-update: updater not found at %s\n' "$UPDATER" >&2
    exit 127
fi

total=0
shopt -s nullglob
for count_file in "$CACHE_DIR"/*.count; do
    count=$(awk 'NR == 1 && /^[0-9]+$/ { print; exit }' "$count_file")
    count=${count:-0}
    printf '%s\n' "$count" > "$count_file"
    total=$((total + count))
done

if [ "$total" -eq 0 ]; then
    clear
    printf '\033[1;36mOutdated Packages\033[0m\n\n'
    if [ -f "$CACHE_DIR/checking" ]; then
        printf 'Checking for outdated packages...\n'
    else
        printf '\033[1;32mAll packages are up to date!\033[0m\n'
    fi
    printf '\nPress any key to close.'
    IFS= read -r -n 1 -s _ || true
    printf '\n'
    exit 0
fi

exec "$UPDATER"
