#!/usr/bin/env bash
# Shared helpers for the macOS bootstrapper. This file is sourced by
# mac/install.sh and intentionally has no side effects beyond defining helpers.

have() { command -v "$1" >/dev/null 2>&1; }

ok() {
    printf 'ok %s\n' "$*"
}

change() {
    CHANGES=$((CHANGES + 1))
    if ${CHECK_MODE:-false}; then
        # shellcheck disable=SC2034 # global consumed by the sourcing installer
        DRIFT=1
    fi
    printf 'change %s\n' "$*"
}

warn() {
    WARNINGS=$((WARNINGS + 1))
    printf 'warn %s\n' "$*"
}

fail() {
    # shellcheck disable=SC2034 # global consumed by the sourcing installer
    FAILED=1
    printf 'fail %s\n' "$*"
}

section() {
    printf '\n==> %s\n' "$*"
}

usage_error() {
    printf 'fail %s\n' "$*" >&2
    exit 64
}

pretty_path() {
    local path="$1"
    case "$path" in
        "$HOME")
            printf '~\n'
            ;;
        "$HOME"/*)
            printf '%s/%s\n' '~' "${path#"$HOME"/}"
            ;;
        "$DOTFILES_DIR")
            printf '<repo>\n'
            ;;
        "$DOTFILES_DIR"/*)
            printf '<repo>/%s\n' "${path#"$DOTFILES_DIR"/}"
            ;;
        *)
            printf '%s\n' "$path"
            ;;
    esac
}

canonical_path() {
    local path="$1" dir base
    if [ -d "$path" ] && [ ! -L "$path" ]; then
        (cd -P "$path" && pwd)
        return
    fi

    dir="$(dirname "$path")"
    base="$(basename "$path")"
    (cd -P "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd)" "$base")
}

link_target_path() {
    local link="$1" target dir base
    target="$(readlink "$link")" || return 1
    case "$target" in
        /*) ;;
        *)
            dir="$(dirname "$link")"
            target="$(cd -P "$dir" 2>/dev/null && printf '%s/%s' "$(pwd)" "$target")" || return 1
            ;;
    esac

    dir="$(dirname "$target")"
    base="$(basename "$target")"
    if [ -d "$dir" ]; then
        (cd -P "$dir" && printf '%s/%s\n' "$(pwd)" "$base")
    else
        printf '%s\n' "$target"
    fi
}

resolved_path() {
    local path="$1" target
    if [ -L "$path" ]; then
        target="$(link_target_path "$path")" || return 1
        if [ -e "$target" ] || [ -L "$target" ]; then
            canonical_path "$target"
        else
            return 1
        fi
    elif [ -e "$path" ]; then
        canonical_path "$path"
    else
        return 1
    fi
}

points_into_dotfiles() {
    local path="$1" resolved
    [ -L "$path" ] || return 1
    resolved="$(link_target_path "$path")" || return 1
    case "$resolved" in
        "$DOTFILES_DIR"|"$DOTFILES_DIR"/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

same_resolved_path() {
    local left="$1" right="$2" left_resolved right_resolved
    left_resolved="$(resolved_path "$left")" || return 1
    right_resolved="$(resolved_path "$right")" || return 1
    [ "$left_resolved" = "$right_resolved" ]
}

expand_home_path() {
    local path="$1"
    case "$path" in
        \~)
            printf '%s\n' "$HOME"
            ;;
        \~/*)
            printf '%s/%s\n' "$HOME" "${path#\~/}"
            ;;
        *)
            printf '%s\n' "$path"
            ;;
    esac
}

join_by_comma() {
    local first=true item
    for item in "$@"; do
        if $first; then
            first=false
        else
            printf ','
        fi
        printf '%s' "$item"
    done
}
