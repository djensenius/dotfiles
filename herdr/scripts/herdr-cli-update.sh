#!/usr/bin/env bash
set -uo pipefail

PATH="$HOME/.local/share/mise/shims:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH

# Match the cache path used by interactive tmux/Herdr processes when launchd or
# another sparse environment does not provide TMPDIR.
if [ -z "${TMPDIR:-}" ] && command -v getconf >/dev/null 2>&1; then
    user_tmp=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || true)
    if [ -n "$user_tmp" ]; then
        TMPDIR="$user_tmp"
        export TMPDIR
    fi
fi

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CACHE_DIR="${TMPDIR:-/tmp}/tmux-outdated-packages"
STATUS_HELPER="$SCRIPT_DIR/herdr-status-report.sh"

declare -a manager_ids=()
declare -a manager_names=()
declare -a manager_counts=()
declare -a manager_commands=()
declare -a manager_lists=()
cache_initialized=0

if compgen -G "$CACHE_DIR/*.count" >/dev/null; then
    cache_initialized=1
fi

manager_icon() {
    case "$1" in
        brew) printf '%s' '' ;;
        npm) printf '%s' '' ;;
        pip) printf '%s' '' ;;
        cargo) printf '%s' '' ;;
        composer) printf '%s' '' ;;
        go) printf '%s' '' ;;
        apt) printf '%s' '' ;;
        dnf) printf '%s' '' ;;
        mise) printf '%s' '' ;;
        *) printf '%s' '󰏖' ;;
    esac
}

read_count() {
    local file="$CACHE_DIR/$1" count
    [ -f "$file" ] || return 0
    count=$(awk 'NR == 1 && /^[0-9]+$/ { print; exit }' "$file")
    [ -n "$count" ] || return 0
    printf '%s' "$count"
}

add_manager() {
    local id="$1" name="$2" count_file="$3" command="$4" list_file="$5" count
    count=$(read_count "$count_file")
    [ -n "$count" ] && [ "$count" -gt 0 ] 2>/dev/null || return 0

    manager_ids+=("$id")
    manager_names+=("$name")
    manager_counts+=("$count")
    manager_commands+=("$command")
    manager_lists+=("$list_file")
}

add_manager brew "Homebrew" brew.count "brew upgrade" brew.list
add_manager npm "npm" npm.count "npm update -g" npm.list
add_manager cargo "Cargo" cargo.count "cargo install-update -a" cargo.list
add_manager composer "Composer" composer.count "composer global update" composer.list
add_manager go "Go" go.count "go-global-update" go.list
add_manager apt "Apt" apt.count "sudo apt upgrade" apt.list
add_manager dnf "DNF" dnf.count "sudo dnf upgrade" dnf.list
add_manager mise "Mise" mise.count "mise upgrade" mise.list
add_manager pip "pip" pip.count "pip3 install --upgrade <packages>" pip.list

BOLD=$'\033[1m'
DIM=$'\033[2m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
CYAN=$'\033[36m'
RESET=$'\033[0m'

draw_screen() {
    local i list_file
    if [ "${1:-}" = '--clear' ] && [ -t 1 ]; then
        clear
    fi

    printf '%s\n' "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    printf '%s\n' "${BOLD}${CYAN}║${RESET}                    📦 ${BOLD}Outdated Packages${RESET}                  ${BOLD}${CYAN}║${RESET}"
    printf '%s\n\n' "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"

    if [ "${#manager_ids[@]}" -eq 0 ]; then
        if [ "$cache_initialized" -eq 0 ]; then
            printf '  %s\n\n' "${YELLOW}${BOLD}Package status is not available yet; checking now.${RESET}"
        else
            printf '  %s\n\n' "${GREEN}${BOLD}All packages are up to date!${RESET}"
        fi
        return
    fi

    for ((i = 0; i < ${#manager_ids[@]}; i++)); do
        printf '  %s%d)%s %s%s %s%s  %s%s outdated%s\n' \
            "$YELLOW" "$((i + 1))" "$RESET" \
            "$BOLD" "$(manager_icon "${manager_ids[$i]}")" "${manager_names[$i]}" "$RESET" \
            "$YELLOW" "${manager_counts[$i]}" "$RESET"
        printf '     %s%s%s\n' "$DIM" "${manager_commands[$i]}" "$RESET"

        list_file="$CACHE_DIR/${manager_lists[$i]}"
        if [ -f "$list_file" ]; then
            while IFS= read -r line; do
                [ -n "$line" ] && printf '       %s%s%s\n' "$DIM" "$line" "$RESET"
            done <"$list_file"
        fi
        printf '\n'
    done

    if [ "${#manager_ids[@]}" -gt 1 ]; then
        printf '  %sa)%s %sUpdate all%s %s(runs each sequentially)%s\n\n' \
            "$YELLOW" "$RESET" "$BOLD" "$RESET" "$DIM" "$RESET"
    fi
    printf '  %sq)%s %sQuit%s\n\n' "$YELLOW" "$RESET" "$DIM" "$RESET"
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'cli-update: required command not found: %s\n' "$1" >&2
        return 127
    fi
}

pip_upgrade_all() {
    local list_file="$CACHE_DIR/pip.list" package found=0 failed=0
    if [ ! -f "$list_file" ]; then
        printf 'cli-update: no pip package list found\n' >&2
        return 1
    fi

    require_command pip3 || return
    while IFS= read -r package; do
        [ -n "$package" ] || continue
        found=1
        printf '%sUpgrading %s...%s\n' "$BOLD" "$package" "$RESET"
        pip3 install --upgrade "$package" || failed=1
    done < <(awk 'NR > 2 { print $1 }' "$list_file")
    if [ "$found" -eq 0 ]; then
        printf 'cli-update: pip package list is empty\n' >&2
        return 1
    fi
    return "$failed"
}

run_upgrade() {
    case "$1" in
        brew)
            require_command brew && brew upgrade
            ;;
        npm)
            require_command npm && npm update -g
            ;;
        cargo)
            require_command cargo-install-update && cargo install-update -a
            ;;
        composer)
            require_command composer && composer global update
            ;;
        go)
            require_command go-global-update && go-global-update
            ;;
        apt)
            require_command apt && require_command sudo && sudo apt upgrade
            ;;
        dnf)
            require_command dnf && require_command sudo && sudo dnf upgrade
            ;;
        mise)
            require_command mise && mise upgrade
            ;;
        pip)
            pip_upgrade_all
            ;;
        *)
            printf 'cli-update: unsupported package manager: %s\n' "$1" >&2
            return 2
            ;;
    esac
}

refresh_cache() {
    local pid_file="$CACHE_DIR/poller.pid" pid=''
    if [ -f "$pid_file" ]; then
        pid=$(awk 'NR == 1 && /^[0-9]+$/ { print; exit }' "$pid_file")
    fi

    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill -USR1 "$pid"
        return
    fi

    "$STATUS_HELPER" --ensure-poller
}

pause_before_close() {
    if [ -t 0 ]; then
        printf '\n%sPress any key to close.%s' "$DIM" "$RESET"
        IFS= read -r -n 1 -s _ || true
        printf '\n'
    fi
}

update_one() {
    local index="$1" status=0
    printf '\n%s%sUpdating %s...%s\n' "$BOLD" "$CYAN" "${manager_names[$index]}" "$RESET"
    printf '%sRunning: %s%s\n\n' "$DIM" "${manager_commands[$index]}" "$RESET"

    if run_upgrade "${manager_ids[$index]}"; then
        printf '\n%s%s updated successfully.%s\n' "$GREEN" "${manager_names[$index]}" "$RESET"
    else
        status=$?
        printf '\n%s%s update failed (exit %d).%s\n' \
            "$RED" "${manager_names[$index]}" "$status" "$RESET" >&2
    fi

    if ! refresh_cache; then
        printf '%sPackage cache refresh could not be requested.%s\n' "$YELLOW" "$RESET" >&2
        [ "$status" -ne 0 ] || status=1
    fi
    pause_before_close
    return "$status"
}

update_all() {
    local i failed=0
    for ((i = 0; i < ${#manager_ids[@]}; i++)); do
        printf '\n%s%sUpdating %s...%s\n' "$BOLD" "$CYAN" "${manager_names[$i]}" "$RESET"
        printf '%sRunning: %s%s\n\n' "$DIM" "${manager_commands[$i]}" "$RESET"
        if run_upgrade "${manager_ids[$i]}"; then
            printf '\n%s%s updated successfully.%s\n' "$GREEN" "${manager_names[$i]}" "$RESET"
        else
            printf '\n%s%s update failed.%s\n' "$RED" "${manager_names[$i]}" "$RESET" >&2
            failed=1
        fi
    done

    if ! refresh_cache; then
        printf '%sPackage cache refresh could not be requested.%s\n' "$YELLOW" "$RESET" >&2
        failed=1
    fi
    pause_before_close
    return "$failed"
}

list_only=0
case "${1:-}" in
    --list)
        list_only=1
        ;;
    '')
        ;;
    *)
        printf 'Usage: cli-update [--list]\n' >&2
        exit 2
        ;;
esac

if [ "$cache_initialized" -eq 0 ] && ! "$STATUS_HELPER" --ensure-poller; then
    printf 'cli-update: unable to start the package-status poller\n' >&2
    exit 1
fi

if [ "$list_only" -eq 1 ]; then
    draw_screen
    exit 0
fi

if [ ! -t 0 ]; then
    draw_screen
    exit 0
fi

while true; do
    draw_screen --clear
    if [ "${#manager_ids[@]}" -eq 0 ]; then
        pause_before_close
        exit 0
    fi

    printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$CYAN" "$RESET"
    printf '%sSelect an option: %s' "$BOLD" "$RESET"
    if ! IFS= read -r choice; then
        exit 0
    fi

    case "$choice" in
        q | Q | '')
            exit 0
            ;;
        a | A)
            if [ "${#manager_ids[@]}" -gt 1 ]; then
                update_all
                exit $?
            fi
            ;;
        *[!0-9]*)
            printf '%sInvalid selection.%s\n' "$RED" "$RESET"
            sleep 1
            ;;
        *)
            index=$((10#$choice - 1))
            if [ "$index" -ge 0 ] && [ "$index" -lt "${#manager_ids[@]}" ]; then
                update_one "$index"
                exit $?
            fi
            printf '%sInvalid selection.%s\n' "$RED" "$RESET"
            sleep 1
            ;;
    esac
done
