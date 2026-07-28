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
# and tmux-outdated-packages, the latter as icon/count pairs packed a few to
# a row.
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
#   HERDR_STATUS_PER_ROW    package entries per sidebar row (default: 3)
#   HERDR_SOCKET_PATH       herdr API socket (honoured by the herdr CLI too)
#   HERDR_STATUS_HEARTS     battery hearts to render (default: 5)
set -uo pipefail

# launchd runs with a minimal PATH; mise shims hold battery_hearts, and herdr
# itself lives in homebrew.
PATH="$HOME/.local/share/mise/shims:/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH

SOURCE_ID='dotfiles-status'
LABEL="${HERDR_STATUS_WORKSPACE:-status}"
PIN="${HERDR_STATUS_PIN:-1}"
SOCKET="${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}"
# The CLI reads HERDR_SOCKET_PATH too; export it so `herdr workspace` and the raw
# nc calls below can never end up talking to two different servers.
export HERDR_SOCKET_PATH="$SOCKET"
OUTDATED_CACHE="${TMPDIR:-/tmp}/tmux-outdated-packages"

log() { printf 'herdr-status: %s\n' "$1" >&2; }

# The overrides are arithmetic, so a typo would otherwise surface as a broken
# expansion or a rejected request rather than a bad setting.
bounded() {
    local name="$1" value="$2" min="$3" max="$4" fallback="$5"
    case "$value" in
        '' | *[!0-9]*)
            log "$name='$value' is not a positive integer; using $fallback"
            printf '%s' "$fallback"
            return
            ;;
    esac
    # Strip leading zeros so 08 is not read as invalid octal.
    value=$((10#$value))
    if [ "$value" -lt "$min" ] || [ "$value" -gt "$max" ]; then
        log "$name=$value is outside $min-$max; clamping"
        [ "$value" -lt "$min" ] && value="$min" || value="$max"
    fi
    printf '%s' "$value"
}

# Herdr caps metadata ttl_ms at 86_400_000 and rejects the whole report past it;
# the TTL is three intervals, so the interval itself tops out at 8 hours.
INTERVAL=$(bounded HERDR_STATUS_INTERVAL "${HERDR_STATUS_INTERVAL:-300}" 1 28800 300)
PER_ROW=$(bounded HERDR_STATUS_PER_ROW "${HERDR_STATUS_PER_ROW:-3}" 1 6 3)
HEARTS=$(bounded HERDR_STATUS_HEARTS "${HERDR_STATUS_HEARTS:-5}" 1 20 5)

# Managers are packed into rows in this order, skipping any that are up to date,
# so the card stays compact instead of reserving a line per manager.
MANAGERS=(brew npm pip cargo go mise)
# config.toml declares a row per manager, which is the worst case (PER_ROW=1);
# anything higher just leaves the spares unreported and therefore hidden.
MAX_ROWS=${#MANAGERS[@]}

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
    battery_hearts --max-hearts "$HEARTS" 2>/dev/null | tr -d '\n'
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
    local ws battery count manager entry row i output args=() entries=()
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

    # Icon plus count only -- the glyph already names the manager, and dropping
    # the word is what fits three entries on a sidebar row.
    for manager in "${MANAGERS[@]}"; do
        count=$(manager_count "$manager")
        [ -n "$count" ] || continue
        entries+=("$(manager_icon "$manager") $count")
    done

    # Pack the survivors PER_ROW at a time and clear the rows left over, so the
    # card shrinks as managers catch up rather than stranding old counts.
    for ((i = 0; i < MAX_ROWS; i++)); do
        row=''
        for entry in "${entries[@]:$((i * PER_ROW)):$PER_ROW}"; do
            [ -n "$row" ] && row="$row  "
            row="$row$entry"
        done
        if [ -n "$row" ]; then
            args+=(--token "pkg_row$((i + 1))=$row")
        else
            args+=(--clear-token "pkg_row$((i + 1))")
        fi
    done

    # Tokens are display-only and never persisted, so each pass restates them.
    # The TTL outlives one missed refresh, then expires, so a dead reporter
    # leaves no frozen readings on the card.
    if ! output=$(herdr workspace report-metadata "$ws" \
        --source "$SOURCE_ID" \
        --ttl-ms $((INTERVAL * 3000)) \
        "${args[@]}" 2>&1); then
        # The server explains itself (invalid_metadata_ttl, unknown workspace),
        # so surface it rather than exiting 0 on a card that never refreshed.
        log "report-metadata failed: $(printf '%s' "$output" | tr '\n' ' ')"
        return 1
    fi

    pin_to_top "$ws"
}

clear_all() {
    local ws i output args=()
    ws=$(resolve_workspace)
    [ -n "$ws" ] || return 1
    args+=(--clear-token battery)
    for ((i = 1; i <= MAX_ROWS; i++)); do
        args+=(--clear-token "pkg_row$i")
    done
    if ! output=$(herdr workspace report-metadata "$ws" --source "$SOURCE_ID" "${args[@]}" 2>&1); then
        log "clear failed: $(printf '%s' "$output" | tr '\n' ' ')"
        return 1
    fi
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
