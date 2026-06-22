#!/usr/bin/env sh
set -eu

HELPER="$HOME/.config/tmux/plugins/tmux-contextual-window-name/bin/tmux-contextual-window-name"

pane=""
command=""
path=""
title=""
pane_pid=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --pane)
            pane="${2:-}"
            shift 2
            ;;
        --command)
            command="${2:-}"
            shift 2
            ;;
        --path)
            path="${2:-}"
            shift 2
            ;;
        --title)
            title="${2:-}"
            shift 2
            ;;
        --pane-pid)
            pane_pid="${2:-}"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

fallback() {
    exec "$HELPER" name --pane "$pane" --command "$command" --path "$path" --title "$title" --pane-pid "$pane_pid"
}

truncate() {
    value="$1"
    max="$2"
    length=$(printf "%s" "$value" | wc -c | tr -d ' ')
    if [ "$length" -le "$max" ]; then
        printf "%s" "$value"
    else
        prefix_len=$((max - 1))
        printf "%s…" "$(printf "%s" "$value" | cut -c "1-$prefix_len")"
    fi
}

path_slug() {
    target="${1:-}"
    fallback_value="${2:-}"

    if [ -z "$target" ]; then
        printf "%s" "$fallback_value"
        return
    fi

    if [ "$target" = "$HOME" ]; then
        printf "~"
        return
    fi

    if [ -d "$target" ]; then
        dir="$target"
    else
        dir=$(dirname "$target")
    fi

    while [ "$dir" != "/" ] && [ -n "$dir" ]; do
        if [ -d "$dir/.git" ] || [ -f "$dir/.git" ]; then
            name=${dir%/}
            printf "%s" "${name##*/}"
            return
        fi
        dir=$(dirname "$dir")
    done

    name=${target%/}
    printf "%s" "${name##*/}"
}

cmd=$(basename "${command:-}")

case "$title" in
    "🤖 "*|"Copilot: "|"Copilot: "*|"GitHub Copilot")
        fallback
        ;;
esac

case "$cmd" in
    node|nodejs|copilot)
        fallback
        ;;
    nvim|fish)
        truncate "$(path_slug "$path" "$cmd")" 24
        ;;
    *)
        truncate "${cmd:-$(path_slug "$path" "")}" 16
        ;;
esac
