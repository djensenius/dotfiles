#!/usr/bin/env bash
# Ambient host status for herdr's sidebar.
#
# Herdr has no status bar and its sidebar sections ("spaces" and "agents") are
# hardcoded, so there is nowhere to pin machine-wide readings. The workaround:
# a space row built only from $custom tokens is dropped for any workspace that
# does not report them (src/ui/sidebar/tokens.rs), so pushing tokens to a single
# workspace turns that one card into a de-facto status section.
#
# This ports the tmux status-right modules that were left behind: battery_hearts
# and tmux-outdated-packages, the latter broken out one manager per line.
#
# Usage:
#   herdr-status-report.sh            report once
#   herdr-status-report.sh --watch    report every $HERDR_STATUS_INTERVAL seconds
#   herdr-status-report.sh --clear    remove the tokens
#
# Env:
#   HERDR_STATUS_WORKSPACE  workspace label to decorate (default: status)
#   HERDR_STATUS_INTERVAL   seconds between refreshes in --watch (default: 300)
#   HERDR_STATUS_PIN        1 to keep the card first in the sidebar (default: 1)
set -uo pipefail

# launchd runs with a minimal PATH; mise shims hold battery_hearts, and herdr
# itself lives in homebrew.
PATH="$HOME/.local/share/mise/shims:/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH

SOURCE_ID='dotfiles-status'
LABEL="${HERDR_STATUS_WORKSPACE:-status}"
INTERVAL="${HERDR_STATUS_INTERVAL:-300}"
PIN="${HERDR_STATUS_PIN:-1}"
SOCKET="${HERDR_SOCKET:-$HOME/.config/herdr/herdr.sock}"
OUTDATED_CACHE="${TMPDIR:-/tmp}/tmux-outdated-packages"

# One token per manager, so each gets its own sidebar row. Order matches the
# rows in config.toml.
MANAGERS=(brew npm pip cargo go mise)

log() { printf 'herdr-status: %s\n' "$1" >&2; }

# workspace.list and report-metadata have CLI wrappers, but workspace.move does
# not in herdr 0.7.5 -- it is socket-only -- so reads go over the socket too.
api() {
    local method="$1" params="$2"
    printf '{"id":"herdr-status","method":"%s","params":%s}\n' "$method" "$params" |
        nc -U "$SOCKET" 2>/dev/null
}

# Workspace ids are assigned by the server and change between sessions, so the
# card is located by label on every pass.
resolve_workspace() {
    api workspace.list '{}' |
        jq -r --arg label "$LABEL" \
            '.result.workspaces[]? | select(.label == $label) | .workspace_id' 2>/dev/null |
        head -n 1
}

battery_token() {
    command -v battery_hearts >/dev/null 2>&1 || return 0
    battery_hearts 2>/dev/null | tr -d '\n'
}

# Nerd font glyphs, matching tmux-outdated-packages/scripts/icons.sh. Kept as
# literal characters because launchd resolves `env bash` to macOS' bash 3.2,
# whose printf has no \uXXXX escape and would emit the escape verbatim.
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

# counts-only.sh sums brew/npm/gem/pipx only, which misses cargo, go, mise and
# pip entirely; the per-manager cache files are the real source.
manager_count() {
    local file="$OUTDATED_CACHE/$1.count" count
    [ -f "$file" ] || return 0
    # Counts occasionally land in the cache with stray blank lines.
    count=$(tr -dc '0-9' <"$file" 2>/dev/null | head -c 6)
    [ -n "$count" ] && [ "$count" -gt 0 ] 2>/dev/null || return 0
    printf '%s' "$count"
}

pin_to_top() {
    local ws="$1" first
    [ "$PIN" = '1' ] || return 0
    first=$(api workspace.list '{}' | jq -r '.result.workspaces[0]?.workspace_id' 2>/dev/null)
    # Skip the write when it is already first, so a manual drag is not fought
    # over on every tick.
    [ "$first" = "$ws" ] && return 0
    api workspace.move "{\"workspace_id\":\"$ws\",\"insert_index\":0}" >/dev/null
}

report_once() {
    local ws battery count manager args=()
    ws=$(resolve_workspace)
    if [ -z "$ws" ]; then
        log "no workspace labelled '$LABEL' (server down, or not created yet)"
        return 1
    fi

    battery=$(battery_token)
    if [ -n "$battery" ]; then
        args+=(--token "battery=$battery")
    else
        args+=(--clear-token battery)
    fi

    for manager in "${MANAGERS[@]}"; do
        count=$(manager_count "$manager")
        if [ -n "$count" ]; then
            args+=(--token "pkg_$manager=$(manager_icon "$manager") $manager $count")
        else
            # Clearing rather than skipping drops the row once a manager is back
            # up to date, instead of leaving the last count on screen.
            args+=(--clear-token "pkg_$manager")
        fi
    done

    # Tokens are display-only and never persisted, so each pass restates them.
    # The TTL outlives one missed refresh, then expires, so a dead reporter
    # leaves no frozen readings on the card.
    herdr workspace report-metadata "$ws" \
        --source "$SOURCE_ID" \
        --ttl-ms $((INTERVAL * 3000)) \
        "${args[@]}" >/dev/null 2>&1

    pin_to_top "$ws"
}

clear_all() {
    local ws manager args=()
    ws=$(resolve_workspace)
    [ -n "$ws" ] || return 1
    args+=(--clear-token battery)
    for manager in "${MANAGERS[@]}"; do
        args+=(--clear-token "pkg_$manager")
    done
    herdr workspace report-metadata "$ws" --source "$SOURCE_ID" "${args[@]}" >/dev/null 2>&1
}

command -v herdr >/dev/null 2>&1 || { log 'herdr not on PATH'; exit 0; }
command -v jq >/dev/null 2>&1 || { log 'jq not on PATH'; exit 0; }
command -v nc >/dev/null 2>&1 || { log 'nc not on PATH'; exit 0; }
[ -S "$SOCKET" ] || { log 'herdr server not running'; exit 0; }

case "${1:-}" in
    --clear)
        clear_all
        ;;
    --watch)
        while true; do
            report_once
            sleep "$INTERVAL"
        done
        ;;
    '')
        report_once
        ;;
    *)
        log "unknown argument: $1"
        exit 2
        ;;
esac
