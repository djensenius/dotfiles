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
#   herdr-status-report.sh --wait-poller   wait for a complete cache refresh
#   herdr-status-report.sh --cache-ready   check for a complete, fresh cache
#   herdr-status-report.sh --refresh-poller refresh it, starting it if needed
#   herdr-status-report.sh --run-poller    run the poller under a service manager
#   herdr-status-report.sh                 same as --ensure-poller
#
# Env:
#   HERDR_STATUS_MAX_AGE  ignore package counts older than N seconds (default:
#                         3600; 0 disables)
#   HERDR_STATUS_WAIT_TIMEOUT maximum seconds to wait for a complete refresh
#                         (default: 250)
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
COMPLETE_FILE="$OUTDATED_CACHE/complete"
CHECKING_FILE="$OUTDATED_CACHE/checking"
LAUNCH_LABEL='dev.djensenius.herdr-status'
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
WAIT_TIMEOUT=$(bounded \
    HERDR_STATUS_WAIT_TIMEOUT "${HERDR_STATUS_WAIT_TIMEOUT:-250}" 1 600 250)

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
    local running_pid
    running_poller_pid >/dev/null && return 0

    if [ ! -x "$OUTDATED_POLLER" ]; then
        log "outdated-package poller not found at $OUTDATED_POLLER"
        return 127
    fi
    mkdir -p "$OUTDATED_CACHE"

    case "$(uname -s)" in
        Darwin)
            start_poller_launch_agent || return
            ;;
        *)
            if ! command -v setsid >/dev/null 2>&1; then
                log 'cannot start poller outside this pane: setsid is unavailable'
                return 127
            fi
            setsid -f "$OUTDATED_POLLER" \
                >>"$OUTDATED_CACHE/herdr-poller.log" 2>&1 </dev/null
            ;;
    esac

    if running_pid=$(wait_for_running_poller); then
        log "started outdated-package poller (pid $running_pid)"
        return 0
    fi
    log 'failed to start outdated-package poller'
    return 1
}

running_poller_pid() {
    local pid_file="$OUTDATED_CACHE/poller.pid" pid recorded_start actual_start
    local process_command
    [ -f "$pid_file" ] || return 1
    pid=$(awk 'NR == 1 && /^[0-9]+$/ { print; exit }' "$pid_file")
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null || return 1

    recorded_start=$(awk 'NR == 2 {$1 = $1; print; exit}' "$pid_file")
    if [ -n "$recorded_start" ]; then
        actual_start=$(LC_ALL=C ps -ww -p "$pid" -o lstart= 2>/dev/null |
            awk '{$1 = $1; print; exit}')
        if [ -z "$actual_start" ] || [ "$recorded_start" != "$actual_start" ]; then
            return 1
        fi
    fi

    process_command=$(ps -ww -p "$pid" -o command= 2>/dev/null) || return 1
    if [ -n "$recorded_start" ]; then
        case "$process_command" in
            *'/scripts/poller.sh'*)
                printf '%s' "$pid"
                ;;
            *)
                return 1
                ;;
        esac
    else
        case "$process_command" in
            *"$OUTDATED_POLLER"*)
                printf '%s' "$pid"
                ;;
            *)
                return 1
                ;;
        esac
    fi
}

wait_for_running_poller() {
    local attempts=0 pid
    while [ "$attempts" -lt 50 ]; do
        if pid=$(running_poller_pid); then
            printf '%s' "$pid"
            return 0
        fi
        attempts=$((attempts + 1))
        sleep 0.1
    done
    return 1
}

start_poller_launch_agent() {
    local domain job
    local plist="$HOME/Library/LaunchAgents/$LAUNCH_LABEL.plist"
    local definition

    domain="gui/$(id -u)"
    job="$domain/$LAUNCH_LABEL"

    if [ ! -f "$plist" ]; then
        log "launch agent is not installed at $plist"
        return 1
    fi

    if definition=$(launchctl print "$job" 2>/dev/null); then
        case "$definition" in
            *'--run-poller'*) ;;
            *)
                launchctl bootout "$domain" "$plist" 2>/dev/null || true
                launchctl bootstrap "$domain" "$plist" || return
                ;;
        esac
    else
        launchctl bootstrap "$domain" "$plist" || return
    fi

    launchctl kickstart "$job"
}

run_outdated_poller() {
    if [ ! -x "$OUTDATED_POLLER" ]; then
        log "outdated-package poller not found at $OUTDATED_POLLER"
        return 127
    fi
    mkdir -p "$OUTDATED_CACHE"
    exec "$OUTDATED_POLLER"
}

refresh_outdated_poller() {
    local manager
    mkdir -p "$OUTDATED_CACHE"
    rm -f "$COMPLETE_FILE"
    while IFS= read -r manager; do
        [ -n "$manager" ] || continue
        rm -f "$OUTDATED_CACHE/$manager.count" "$OUTDATED_CACHE/$manager.list"
    done < <(expected_package_managers)
    ensure_outdated_poller
}

expected_package_managers() {
    command -v brew >/dev/null 2>&1 && printf '%s\n' brew
    command -v npm >/dev/null 2>&1 && printf '%s\n' npm
    command -v pip3 >/dev/null 2>&1 && printf '%s\n' pip
    if command -v cargo >/dev/null 2>&1 &&
        command -v cargo-install-update >/dev/null 2>&1; then
        printf '%s\n' cargo
    fi
    command -v composer >/dev/null 2>&1 && printf '%s\n' composer
    if command -v go >/dev/null 2>&1 &&
        command -v go-global-update >/dev/null 2>&1; then
        printf '%s\n' go
    fi
    if command -v apt >/dev/null 2>&1 &&
        { [ -r /var/lib/apt/lists ] || [ "$EUID" -eq 0 ]; }; then
        printf '%s\n' apt
    fi
    command -v dnf >/dev/null 2>&1 && printf '%s\n' dnf
    command -v mise >/dev/null 2>&1 && printf '%s\n' mise
}

count_file_is_usable() {
    local file="$1"
    [ -f "$file" ] || return 1
    awk 'NR == 1 && /^[0-9]+$/ { found = 1 } END { exit !found }' "$file" ||
        return 1
}

completion_is_usable() {
    local marker="${1:-}" mtime age
    [ -f "$COMPLETE_FILE" ] && [ ! -e "$CHECKING_FILE" ] || return 1
    if [ -n "$marker" ]; then
        [ "$COMPLETE_FILE" -nt "$marker" ]
        return
    fi

    [ "$MAX_AGE" -gt 0 ] || return 0
    mtime=$(stat -f %m "$COMPLETE_FILE" 2>/dev/null ||
        stat -c %Y "$COMPLETE_FILE" 2>/dev/null)
    [ -n "$mtime" ] || return 1
    age=$(($(date +%s) - mtime))
    [ "$age" -le "$MAX_AGE" ]
}

package_cache_is_ready() {
    local marker="${1:-}" manager count_file list_file expected=0
    completion_is_usable "$marker" || return
    while IFS= read -r manager; do
        [ -n "$manager" ] || continue
        expected=1
        count_file="$OUTDATED_CACHE/$manager.count"
        list_file="$OUTDATED_CACHE/$manager.list"
        count_file_is_usable "$count_file" || return 1
        [ -f "$list_file" ] || return 1
        [ ! "$count_file" -nt "$COMPLETE_FILE" ] || return 1
        [ ! "$list_file" -nt "$COMPLETE_FILE" ] || return 1
    done < <(expected_package_managers)
    [ "$expected" -eq 1 ] && completion_is_usable "$marker"
}

remove_refresh_marker() {
    rm -f "$1"
    trap - INT TERM
}

wait_for_outdated_poller() {
    local deadline marker expected
    ensure_outdated_poller || return
    package_cache_is_ready && return 0

    expected=$(expected_package_managers)
    [ -n "$expected" ] || return 0

    marker="$OUTDATED_CACHE/herdr-refresh.$$"
    : >"$marker"
    trap 'rm -f "$marker"; exit 130' INT TERM
    if ! refresh_outdated_poller; then
        remove_refresh_marker "$marker"
        return 1
    fi
    deadline=$(($(date +%s) + WAIT_TIMEOUT))

    until package_cache_is_ready "$marker"; do
        if ! running_poller_pid >/dev/null; then
            remove_refresh_marker "$marker"
            log 'outdated-package poller exited before completing a check'
            return 1
        fi
        if [ "$(date +%s)" -ge "$deadline" ]; then
            remove_refresh_marker "$marker"
            log 'timed out waiting for outdated-package checks'
            return 1
        fi
        sleep 1
    done
    remove_refresh_marker "$marker"
}

case "${1:-}" in
    --tab-bar)
        render_tab_bar
        ;;
    --ensure-poller | '')
        ensure_outdated_poller
        ;;
    --wait-poller)
        wait_for_outdated_poller
        ;;
    --cache-ready)
        package_cache_is_ready
        ;;
    --refresh-poller)
        refresh_outdated_poller
        ;;
    --run-poller)
        run_outdated_poller
        ;;
    *)
        log "unknown argument: $1"
        exit 2
        ;;
esac
