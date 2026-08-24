#!/usr/bin/env bash
# Format battery and outdated-package state for Herdr's right-aligned tab bar.
#
# The tmux-outdated-packages poller owns the shared cache. Herdr's status
# command is deliberately read-only because Herdr terminates a status command's
# entire process group after each run, including background children.
#
# Usage:
#   herdr-status-report.sh --tab-bar       print one status line
#   herdr-status-report.sh --ensure-poller start the shared poller if needed
#   herdr-status-report.sh                 same as --ensure-poller (launchd compatibility)
#
# Env:
#   HERDR_STATUS_MAX_AGE  ignore package counts older than N seconds (default:
#                         3600; 0 disables)
#   HERDR_STATUS_POLLER   tmux-outdated-packages poller path
#   HERDR_STATUS_HEARTS   battery hearts to render (default: 5)
set -uo pipefail

PATH="$HOME/.local/share/mise/shims:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH

# launchd does not inherit TMPDIR, while interactive tmux and Herdr processes
# do. Resolve macOS' per-user temporary directory so every caller shares one
# package cache.
if [ -z "${TMPDIR:-}" ] && command -v getconf >/dev/null 2>&1; then
    user_tmp=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || true)
    if [ -n "$user_tmp" ]; then
        TMPDIR="$user_tmp"
        export TMPDIR
    fi
fi

OUTDATED_CACHE="${TMPDIR:-/tmp}/tmux-outdated-packages"
OUTDATED_POLLER="${HERDR_STATUS_POLLER:-$HOME/.config/tmux/plugins/tmux-outdated-packages/scripts/poller.sh}"
MANAGERS=(brew npm pip cargo go mise)

log() { printf 'herdr-status: %s\n' "$1" >&2; }

bounded() {
    local name="$1" value="$2" min="$3" max="$4" fallback="$5"
    case "$value" in
        '' | *[!0-9]*)
            log "$name='$value' is not a non-negative integer; using $fallback"
            printf '%s' "$fallback"
            return
            ;;
    esac

    value=$((10#$value))
    if [ "$value" -lt "$min" ] || [ "$value" -gt "$max" ]; then
        log "$name=$value is outside $min-$max; clamping"
        [ "$value" -lt "$min" ] && value="$min" || value="$max"
    fi
    printf '%s' "$value"
}

HEARTS=$(bounded HERDR_STATUS_HEARTS "${HERDR_STATUS_HEARTS:-5}" 1 20 5)
MAX_AGE=$(bounded HERDR_STATUS_MAX_AGE "${HERDR_STATUS_MAX_AGE:-3600}" 0 604800 3600)

manager_icon() {
    case "$1" in
        brew) printf '%s' '' ;;
        npm) printf '%s' '' ;;
        pip) printf '%s' '' ;;
        cargo) printf '%s' '' ;;
        go) printf '%s' '' ;;
        mise) printf '%s' '' ;;
        *) printf '%s' '󰏖' ;;
    esac
}

manager_count() {
    local file="$OUTDATED_CACHE/$1.count" count mtime age
    [ -f "$file" ] || return 0

    if [ "$MAX_AGE" -gt 0 ]; then
        mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)
        if [ -n "$mtime" ]; then
            age=$(($(date +%s) - mtime))
            if [ "$age" -gt "$MAX_AGE" ]; then
                return 0
            fi
        fi
    fi

    count=$(awk 'NR == 1 && /^[0-9]+$/ { print; exit }' "$file")
    [ -n "$count" ] && [ "$count" -gt 0 ] 2>/dev/null || return 0
    printf '%s' "$count"
}

battery_status() {
    command -v battery_hearts >/dev/null 2>&1 || return 0
    battery_hearts --max-hearts "$HEARTS" 2>/dev/null |
        tr -d '\n' |
        sed 's/[[:space:]]*$//'
}

append_status() {
    local current="$1" addition="$2"
    if [ -n "$current" ] && [ -n "$addition" ]; then
        printf '%s  %s' "$current" "$addition"
    else
        printf '%s%s' "$current" "$addition"
    fi
}

render_tab_bar() {
    local output battery manager count
    output=''
    battery=$(battery_status)
    output=$(append_status "$output" "$battery")

    for manager in "${MANAGERS[@]}"; do
        count=$(manager_count "$manager")
        [ -n "$count" ] || continue
        output=$(append_status "$output" "$(manager_icon "$manager") $count")
    done

    printf '%s\n' "$output"
}

ensure_outdated_poller() {
    local pid_file="$OUTDATED_CACHE/poller.pid" pid=''
    if [ -f "$pid_file" ]; then
        pid=$(awk 'NR == 1 && /^[0-9]+$/ { print; exit }' "$pid_file")
        [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && return 0
    fi

    if [ ! -x "$OUTDATED_POLLER" ]; then
        log "outdated-package poller not found at $OUTDATED_POLLER"
        return 127
    fi

    mkdir -p "$OUTDATED_CACHE"
    nohup "$OUTDATED_POLLER" >>"$OUTDATED_CACHE/herdr-poller.log" 2>&1 </dev/null &
    pid=$!
    if ! kill -0 "$pid" 2>/dev/null; then
        log 'failed to start outdated-package poller'
        return 1
    fi
    log "started outdated-package poller (pid $pid)"
}

case "${1:-}" in
    --tab-bar)
        render_tab_bar
        ;;
    --ensure-poller | '')
        ensure_outdated_poller
        ;;
    *)
        log "unknown argument: $1"
        exit 2
        ;;
esac
