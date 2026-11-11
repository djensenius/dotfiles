#!/usr/bin/env bash
# File-only desktop settings integration. Sourcing this file performs no I/O.

herdr_app_backup_to() {
    local target="$1" backup="$2" runner="${3:-command}"
    "$runner" mkdir -p "$(dirname "$backup")" || return 1
    if [ -L "$target" ] && [ -f "$target" ]; then
        # Moving a relative link would break its backup. Save the actual bytes,
        # leaving the old referent alone, before removing only the link.
        "$runner" cp -pL "$target" "$backup" || return 1
        "$runner" rm "$target" || return 1
    else
        "$runner" mv "$target" "$backup" || return 1
    fi
}

herdr_app_backup_settings() {
    local target="$1" runner="$3" backup="$1.backup" suffix=1
    while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup="$target.backup.$suffix"
        suffix=$((suffix + 1))
    done
    herdr_app_backup_to "$target" "$backup" "$runner" || return 1
    printf 'herdr-app: backed up %s to %s\n' "$target" "$backup"
}

# Arguments: repo root, replace existing settings?, user-command runner,
# optional platform backup function (target, preserve contents, runner).
# DRY_RUN/CHECK_MODE are read-only modes.
link_herdr_app_settings() {
    local repo="$1" replace="${2:-true}" runner="${3:-command}"
    local backup="${4:-herdr_app_backup_settings}"
    local dir="${HERDR_APP_HOME:-$HOME/.config/herdr-app}" source target
    HERDR_APP_SETTINGS_CHANGED=false
    # Strip trailing slash/current-directory components lexically: resolving
    # the path would hide the config-home symlink that the -L guard must reject.
    while [ "$dir" != / ]; do
        case "$dir" in
            */.) dir="${dir%.}" ;;
            */) dir="${dir%/}" ;;
            *) break ;;
        esac
    done
    source="$repo/herdr-app/settings.json"
    target="$dir/settings.json"

    if [ ! -f "$source" ]; then
        printf 'herdr-app: missing repo settings: %s\n' "$source" >&2
        return 1
    fi
    case "$dir" in
        /*) ;;
        *)
            printf 'herdr-app: HERDR_APP_HOME must be an absolute path\n' >&2
            return 1
            ;;
    esac
    # Do not migrate, replace or write through a directory link: everything
    # except settings.json belongs to the app. Ask for a real directory first.
    if [ -L "$dir" ] || { [ -e "$dir" ] && [ ! -d "$dir" ]; }; then
        printf 'herdr-app: config home must be a real directory; left unchanged: %s\n' "$dir" >&2
        return 1
    fi
    if [ -L "$target" ] && [ "$target" -ef "$source" ]; then
        printf 'herdr-app: already linked: %s\n' "$target"
        return 0
    fi
    if [ "$target" -ef "$source" ]; then
        printf 'herdr-app: refusing to replace the repo settings file: %s\n' "$target" >&2
        return 1
    fi
    if ! "$replace" && { [ -e "$target" ] || [ -L "$target" ]; }; then
        printf 'herdr-app: leaving existing %s in place (use --force to replace)\n' "$target"
        return 0
    fi

    # shellcheck disable=SC2034 # consumed by the macOS link-section counters
    HERDR_APP_SETTINGS_CHANGED=true
    if ${DRY_RUN:-false} || ${CHECK_MODE:-false}; then
        if [ -e "$target" ] || [ -L "$target" ]; then
            printf 'herdr-app: would back up %s\n' "$target"
        fi
        printf 'herdr-app: would link %s -> %s (in a real directory)\n' "$target" "$source"
        return 0
    fi

    "$runner" mkdir -p "$dir" || return 1
    if [ -e "$target" ] || [ -L "$target" ]; then
        "$backup" "$target" true "$runner" || return 1
    fi
    "$runner" ln -s "$source" "$target" || return 1
    printf 'herdr-app: linked %s -> %s\n' "$target" "$source"
}
