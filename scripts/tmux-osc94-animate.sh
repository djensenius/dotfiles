#!/usr/bin/env bash
# Animate OSC 9;4 progress flags in the tmux status bar.
#
# Background companion to scripts/tmux-osc94-window-flag.sh and the
# djensenius/tmux-osc-9-4 plugin. The plugin tracks per-pane progress in a
# filesystem store; this daemon aggregates that per *window*, writes an icon
# (an animated spinner for indeterminate/"thinking" progress) into the window
# option `@osc94_flag`, and forces a status redraw with `refresh-client -S`.
#
# Why a daemon instead of a `#()` in the status format: tmux only re-runs
# `#()` shell commands on `status-interval` (5s here) and caches their output.
# A spinner there could only tick every 5s. `refresh-client -S` repaints the
# status line using the *cached* `#()` output, so we get a smooth spinner
# without re-running the expensive window-name / speedtest / battery helpers.
#
# A single instance runs (guarded by a pidfile). It is started from tmux.conf
# via `run-shell -b`. While any pane has active progress it animates at
# ~8 fps; when everything is idle it polls cheaply (~1 s) and issues no
# redraws, so idle cost is just reading a few small JSON files.
#
# Configurable tmux options (with defaults):
#   @osc94_enabled              "on"   master switch (shared with the plugin)
#   @osc94_animate              "on"   "off" = show a static icon, no spinning
#   @osc94_state_dir            state store dir (matches the plugin option)
#   @osc94_flag_spinner         braille frames, space-separated
#   @osc94_flag_icon_normal     state 1 base icon (determinate progress)
#   @osc94_flag_icon_error      state 2 icon
#   @osc94_flag_icon_busy       state 3 base icon (indeterminate / thinking)
#   @osc94_flag_icon_warning    state 4 icon
#   @osc94_flag_show_percent    "on"   append "NN%" for determinate progress
#   @osc94_stale_secs           "15"   drop an indeterminate spinner whose state
#                                      file hasn't updated in N s ("0" disables)
#   @osc94_animate_fps          "8"    spinner frames per second (1-30)
set -uo pipefail

opt() {
    local value
    value=$(tmux show-option -gqv "$1" 2>/dev/null || true)
    if [ -n "$value" ]; then printf '%s' "$value"; else printf '%s' "$2"; fi
}

state_dir=$(opt "@osc94_state_dir" "${XDG_STATE_HOME:-$HOME/.local/state}/tmux-osc-9-4")
# shellcheck disable=SC2088  # literal ~ patterns below are case globs, not expansions
case "$state_dir" in
    "~"|"~/"*) state_dir="$HOME${state_dir#~}" ;;
esac
panes_dir="$state_dir/panes"
lockdir="$state_dir/animate.lock"

mkdir -p "$state_dir"

# Singleton guard. `mkdir` is atomic, so concurrent starts (e.g. two rapid
# config reloads both firing `run-shell -b`) can never both win. The loser
# exits; a stale lock left by a crashed instance is reclaimed once its pid is
# confirmed dead.
acquire_lock() {
    if mkdir "$lockdir" 2>/dev/null; then return 0; fi
    local holder
    holder=$(cat "$lockdir/pid" 2>/dev/null || true)
    if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
        return 1
    fi
    rm -rf "$lockdir"
    mkdir "$lockdir" 2>/dev/null
}
acquire_lock || exit 0
echo "$$" > "$lockdir/pid"

# EXIT cleans up the lock; INT/TERM must explicitly exit (a bare signal trap
# would otherwise just resume the loop, leaving an unkillable daemon).
trap 'rm -rf "$lockdir"' EXIT
trap 'exit 0' INT TERM

json_field() {
    sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p" "$1" 2>/dev/null | head -n1
}

priority() {
    case "$1" in
        2) echo 4 ;;
        4) echo 3 ;;
        1) echo 2 ;;
        3) echo 1 ;;
        *) echo 0 ;;
    esac
}

frame=0
declare -A last_flag=()
# Generation-based staleness tracking. The plugin's "generation" counter only
# advances when a pane actually emits new OSC 9;4 data; its file mtime cannot be
# used because the plugin's sync rewrites every pane file (refreshing mtime)
# even when nothing changed. gen_val holds the last observed generation per
# pane; gen_since holds the epoch when that generation was first seen.
declare -A gen_val=()
declare -A gen_since=()

while true; do
    # Stop entirely if the plugin/flags are disabled; clear any leftover flags.
    if [ "$(opt "@osc94_enabled" "on")" != "on" ]; then
        for win in "${!last_flag[@]}"; do
            tmux set-option -wqu -t "$win" "@osc94_flag" 2>/dev/null || true
        done
        tmux refresh-client -S 2>/dev/null || true
        exit 0
    fi

    animate=$(opt "@osc94_animate" "on")
    show_percent=$(opt "@osc94_flag_show_percent" "on")
    # A genuinely-thinking CLI rewrites its indeterminate (state 3) progress
    # every ~5s, so a state-3 pane whose generation counter has not advanced in
    # this many seconds is treated as stale and dropped. This auto-clears a
    # spinner left behind by a session that exited or froze without sending a
    # clear. "0" disables the timeout. Only affects indeterminate progress;
    # determinate bars (state 1) may legitimately sit without re-emitting.
    stale_secs=$(opt "@osc94_stale_secs" "15")
    case "$stale_secs" in (*[!0-9]*|"") stale_secs=15 ;; esac
    now=$(date +%s)
    fps=$(opt "@osc94_animate_fps" "8")
    case "$fps" in (*[!0-9]*|"") fps=8 ;; esac
    [ "$fps" -lt 1 ] && fps=1
    [ "$fps" -gt 30 ] && fps=30

    IFS=' ' read -r -a spinner <<< "$(opt "@osc94_flag_spinner" "⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏")"
    [ "${#spinner[@]}" -eq 0 ] && spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    spin="${spinner[$((frame % ${#spinner[@]}))]}"

    icon_normal=$(opt "@osc94_flag_icon_normal" "󰦖")
    icon_error=$(opt "@osc94_flag_icon_error" "󰅙")
    icon_busy=$(opt "@osc94_flag_icon_busy" "󰔟")
    icon_warning=$(opt "@osc94_flag_icon_warning" "󰀪")

    # Aggregate per-window best state from the pane store.
    declare -A win_code=()
    declare -A win_prog=()
    declare -A seen_pane=()
    if [ -d "$panes_dir" ]; then
        while read -r win pane; do
            file="$panes_dir/$pane.json"
            [ -f "$file" ] || continue
            seen_pane[$pane]=1
            code=$(json_field "$file" "state_code")
            [ -n "$code" ] || continue
            [ "$code" -eq 0 ] 2>/dev/null && continue
            # Drop a stale indeterminate spinner: a state-3 pane whose
            # generation counter has not advanced within stale_secs is no longer
            # actively thinking (the process exited/froze without clearing).
            if [ "$code" -eq 3 ] 2>/dev/null && [ "$stale_secs" -gt 0 ]; then
                gen=$(json_field "$file" "generation")
                if [ -n "$gen" ]; then
                    if [ "${gen_val[$pane]:-}" != "$gen" ]; then
                        gen_val[$pane]="$gen"
                        gen_since[$pane]="$now"
                    fi
                    if [ "$((now - ${gen_since[$pane]}))" -ge "$stale_secs" ]; then
                        continue
                    fi
                fi
            fi
            cur="${win_code[$win]:-}"
            if [ -z "$cur" ] || [ "$(priority "$code")" -gt "$(priority "$cur")" ]; then
                win_code[$win]="$code"
                win_prog[$win]=$(json_field "$file" "progress")
            fi
        done < <(tmux list-panes -a -F '#{window_id} #{pane_id}' 2>/dev/null)
    fi

    # Forget generation tracking for panes that no longer exist.
    for p in "${!gen_val[@]}"; do
        [ -n "${seen_pane[$p]:-}" ] || unset 'gen_val[$p]' 'gen_since[$p]'
    done

    any_active=0
    changed=0

    # Set/clear the flag for every window; only touch tmux when the value changes.
    while read -r win; do
        [ -n "$win" ] || continue
        code="${win_code[$win]:-}"
        flag=""
        if [ -n "$code" ]; then
            any_active=1
            if [ "$animate" = "on" ]; then base_busy="$spin"; else base_busy="$icon_busy"; fi
            case "$code" in
                1)
                    if [ "$animate" = "on" ]; then flag=" $spin"; else flag=" $icon_normal"; fi
                    if [ "$show_percent" = "on" ] && [ -n "${win_prog[$win]:-}" ]; then
                        flag="$flag ${win_prog[$win]}%"
                    fi
                    ;;
                2) flag=" $icon_error" ;;
                3) flag=" $base_busy" ;;
                4) flag=" $icon_warning" ;;
            esac
        fi
        if [ "${last_flag[$win]:-__unset__}" != "$flag" ]; then
            changed=1
            last_flag[$win]="$flag"
            if [ -n "$flag" ]; then
                tmux set-option -wq -t "$win" "@osc94_flag" "$flag" 2>/dev/null || true
            else
                tmux set-option -wqu -t "$win" "@osc94_flag" 2>/dev/null || true
            fi
        fi
    done < <(tmux list-windows -a -F '#{window_id}' 2>/dev/null)

    unset win_code win_prog seen_pane

    if [ "$any_active" -eq 1 ] && [ "$animate" = "on" ]; then
        tmux refresh-client -S 2>/dev/null || true
        frame=$((frame + 1))
        sleep "$(awk "BEGIN{printf \"%.3f\", 1/$fps}")"
    else
        if [ "$changed" -eq 1 ]; then
            tmux refresh-client -S 2>/dev/null || true
        fi
        sleep 1
    fi
done
