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
# via `run-shell -b`. While any pane has active progress it animates at a
# high, smooth framerate (~20 fps by default); when everything is idle it polls
# cheaply (~0.5 s) and issues no redraws, so idle cost is just reading a few
# small JSON files.
#
# Keeping the framerate real: every per-frame tmux call is a subprocess
# (~10-25 ms), so the hot path is kept minimal — it only advances the spinner
# glyph and issues one `set-option`/`refresh-client` per active window. The
# expensive work (reading ~13 options, scanning every pane's JSON) is hoisted
# out of the per-frame loop: options are pulled in a single `tmux show-options`
# call refreshed ~1/s, and the pane store is re-scanned only ~3/s. Without this
# the ~13 option subprocesses alone (~130 ms) would cap the real rate near
# 5-8 fps regardless of @osc94_animate_fps.
#
# Spinner style: a Copilot-CLI-style pulsing circle (○ ◎ ◉ ●) whose glyph and
# colour brighten/dim together each frame (a gentle "breathing" shimmer),
# rather than a spinning braille dot. The per-frame colour is emitted as a tmux
# `#[fg=...]` style code embedded in `@osc94_flag`; tmux applies it when it
# renders the status line.
#
# Configurable tmux options (with defaults):
#   @osc94_enabled              "on"   master switch (shared with the plugin)
#   @osc94_animate              "on"   "off" = show a static icon, no spinning
#   @osc94_state_dir            state store dir (matches the plugin option)
#   @osc94_flag_spinner         pulse glyph frames, space-separated
#   @osc94_flag_spinner_colors  per-frame colours (same count as frames); a
#                               frame's colour may be "-" for no colouring
#   @osc94_flag_icon_normal     state 1 base icon (determinate progress)
#   @osc94_flag_icon_error      state 2 icon
#   @osc94_flag_icon_busy       state 3 base icon (indeterminate / thinking)
#   @osc94_flag_icon_warning    state 4 icon
#   @osc94_flag_show_percent    "on"   append "NN%" for determinate progress
#   @osc94_stale_secs           "15"   drop an indeterminate spinner whose state
#                                      file hasn't updated in N s ("0" disables)
#   @osc94_animate_fps         "20"   spinner frames per second (1-60)
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
# Per-window aggregated state, refreshed only on a (relatively infrequent) pane
# scan rather than every animation frame.
declare -A win_code=()
declare -A win_prog=()

# Option cache. Reading options is the single most expensive thing this daemon
# does: `tmux show-option` spawns a subprocess (~10 ms) and the original code
# read ~13 options *per frame*, capping the real framerate at well under the
# requested value. We instead pull every option in ONE `tmux show-options -g`
# call and refresh it at most ~1/s, so the per-frame hot path makes no
# option-reading subprocess calls at all.
load_options() {
    o_enabled="on"; animate="on"; show_percent="on"; stale_secs="15"; fps="20"
    icon_normal="󰦖"; icon_error="󰅙"; icon_busy="󰔟"; icon_warning="󰀪"
    local spinner_str="○ ○ ◎ ◎ ◉ ● ● ◉ ◎ ◎ ○ ○"
    local colors_str="#585b70 #6c7086 #7f849c #9399b2 #b4befe #cdd6f4 #cdd6f4 #b4befe #9399b2 #7f849c #6c7086 #585b70"
    local key rest
    while read -r key rest; do
        rest=${rest#\"}; rest=${rest%\"}
        case "$key" in
            @osc94_enabled) o_enabled=$rest ;;
            @osc94_animate) animate=$rest ;;
            @osc94_flag_show_percent) show_percent=$rest ;;
            @osc94_stale_secs) stale_secs=$rest ;;
            @osc94_animate_fps) fps=$rest ;;
            @osc94_flag_icon_normal) icon_normal=$rest ;;
            @osc94_flag_icon_error) icon_error=$rest ;;
            @osc94_flag_icon_busy) icon_busy=$rest ;;
            @osc94_flag_icon_warning) icon_warning=$rest ;;
            @osc94_flag_spinner) [ -n "$rest" ] && spinner_str=$rest ;;
            @osc94_flag_spinner_colors) [ -n "$rest" ] && colors_str=$rest ;;
        esac
    done < <(tmux show-options -g 2>/dev/null)

    case "$stale_secs" in (*[!0-9]*|"") stale_secs=15 ;; esac
    case "$fps" in (*[!0-9]*|"") fps=20 ;; esac
    [ "$fps" -lt 1 ] && fps=1
    [ "$fps" -gt 60 ] && fps=60

    # Copilot-CLI-style pulsing circle: the glyph fills/empties (○ ◎ ◉ ●) while
    # its colour brightens/dims in lockstep, producing a gentle breathing
    # shimmer. Glyph frames and colour frames are positional pairs; a colour of
    # "-" (or a missing entry) renders the glyph uncoloured.
    IFS=' ' read -r -a spinner <<< "$spinner_str"
    [ "${#spinner[@]}" -eq 0 ] && spinner=("○")
    IFS=' ' read -r -a spinner_colors <<< "$colors_str"

    # Frame timing, computed with integer math (no per-frame `awk`/`date`).
    # period_us is the target wall-clock budget per frame; the hot loop sleeps
    # only the remainder after the frame's work (see below) so the real rate
    # tracks fps instead of being (work + 1/fps).
    period_us=$((1000000 / fps))
    local ms=$((1000 / fps)); [ "$ms" -lt 1 ] && ms=1
    # Re-scan the pane store roughly every 300 ms of animation; state changes
    # far slower than the spinner, so there is no need to scan every frame.
    scan_frames=$(( (300 + ms - 1) / ms )); [ "$scan_frames" -lt 1 ] && scan_frames=1
}

# Aggregate per-window best state from the pane store. Updates win_code/win_prog
# in place. Cheap relative to the frame rate but still off the per-frame path.
scan_panes() {
    local now win pane file code gen cur
    printf -v now '%(%s)T' -1
    win_code=(); win_prog=()
    local -A seen_pane=()
    [ -d "$panes_dir" ] || return 0
    while read -r win pane; do
        file="$panes_dir/$pane.json"
        [ -f "$file" ] || continue
        seen_pane[$pane]=1
        code=$(json_field "$file" "state_code")
        [ -n "$code" ] || continue
        [ "$code" -eq 0 ] 2>/dev/null && continue
        # Drop a stale indeterminate spinner: a state-3 pane whose generation
        # counter has not advanced within stale_secs is no longer actively
        # thinking (the process exited/froze without clearing).
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

    # Forget generation tracking for panes that no longer exist.
    for pane in "${!gen_val[@]}"; do
        [ -n "${seen_pane[$pane]:-}" ] || unset 'gen_val[$pane]' 'gen_since[$pane]'
    done
}

# Build the current spinner glyph for this frame (cheap; no tmux subprocess).
# Sets the global `spin`.
build_spin() {
    local idx glyph color
    idx=$((frame % ${#spinner[@]}))
    glyph="${spinner[$idx]}"
    color="${spinner_colors[$idx]:-}"
    if [ -n "$color" ] && [ "$color" != "-" ]; then
        spin="#[fg=$color]$glyph#[fg=default]"
    else
        spin="$glyph"
    fi
}

# Diff the desired flag against the last-applied value for every active window
# (and clear windows that went idle), then issue a single status redraw. Only
# windows whose flag actually changed cost a `set-option`; while animating, the
# spinner glyph changes each frame so active windows are updated every frame,
# but idle windows and the (expensive) pane scan stay off the hot path.
render() {
    local changed=0 win code flag base_busy
    if [ "$animate" = "on" ]; then base_busy="$spin"; else base_busy="$icon_busy"; fi
    for win in "${!win_code[@]}"; do
        code="${win_code[$win]}"
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
            *) flag="" ;;
        esac
        if [ "${last_flag[$win]:-__unset__}" != "$flag" ]; then
            changed=1
            last_flag[$win]="$flag"
            tmux set-option -wq -t "$win" "@osc94_flag" "$flag" 2>/dev/null || true
        fi
    done
    # Clear windows that are no longer active.
    for win in "${!last_flag[@]}"; do
        if [ -z "${win_code[$win]:-}" ]; then
            changed=1
            tmux set-option -wqu -t "$win" "@osc94_flag" 2>/dev/null || true
            unset 'last_flag[$win]'
        fi
    done
    if [ "$changed" -eq 1 ]; then
        tmux refresh-client -S 2>/dev/null || true
    fi
}

load_options
scan_panes
last_opt_load=$(printf '%(%s)T' -1)
frames_since_scan=0

while true; do
    printf -v now_s '%(%s)T' -1
    # Refresh the option cache at most ~1/s so runtime toggles (enable/disable,
    # fps changes) are still picked up without paying for it every frame.
    if [ "$((now_s - last_opt_load))" -ge 1 ]; then
        load_options
        last_opt_load=$now_s
    fi

    # Stop entirely if the plugin/flags are disabled; clear any leftover flags.
    if [ "$o_enabled" != "on" ]; then
        for win in "${!last_flag[@]}"; do
            tmux set-option -wqu -t "$win" "@osc94_flag" 2>/dev/null || true
        done
        tmux refresh-client -S 2>/dev/null || true
        exit 0
    fi

    if [ "$animate" = "on" ] && [ "${#win_code[@]}" -gt 0 ]; then
        # Hot path: animate. Re-scan the pane store only every scan_frames
        # frames; every frame just advances the glyph and repaints.
        frame_start=$EPOCHREALTIME
        if [ "$frames_since_scan" -ge "$scan_frames" ]; then
            scan_panes
            frames_since_scan=0
        fi
        build_spin
        render
        frame=$((frame + 1))
        frames_since_scan=$((frames_since_scan + 1))
        # Pace to the target period: sleep only the time left after this frame's
        # work (set-option + refresh-client cost ~30-50 ms), so the real
        # framerate tracks @osc94_animate_fps rather than (work + 1/fps).
        # $EPOCHREALTIME is a bash builtin (no subprocess); stripping its dot
        # yields integer microseconds since the epoch.
        s_us=${frame_start/./}; e_us=${EPOCHREALTIME/./}
        rem=$((period_us - (e_us - s_us)))
        if [ "$rem" -gt 0 ]; then
            printf -v dur '%d.%06d' "$((rem / 1000000))" "$((rem % 1000000))"
            sleep "$dur"
        fi
    else
        # Idle (nothing active) or static (animation disabled): poll cheaply for
        # new activity, paint once, and sleep. No per-frame redraws.
        scan_panes
        build_spin
        render
        sleep 0.5
    fi
done
