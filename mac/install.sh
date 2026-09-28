#!/usr/bin/env bash
# Homebrew-aware macOS bootstrapper for this dotfiles repository.
# Safe to re-run: it checks each item and only creates missing or drifted pieces.

set -euo pipefail

MAC_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd -P "$MAC_DIR/.." && pwd)"

DRY_RUN=false
CHECK_MODE=false
INSTALL_APPS=false
DRIFT_MODE=false
ADOPT_GITCONFIG=false
SET_FISH_SHELL=false
ASSUME_YES=false
ONLY_SECTIONS=""
SKIP_SECTIONS=""
FAILED=0
DRIFT=0
CHANGES=0
WARNINGS=0
BACKUP_DIR=""
HERDR_REPAIR_DEFERRED=false
LINKS_FILE="${INSTALL_MAC_LINKS_FILE:-$MAC_DIR/links.txt}"

# common.sh is shellchecked on its own; CI runs shellcheck without -x.
# shellcheck source=mac/lib/common.sh disable=SC1091
. "$MAC_DIR/lib/common.sh"

ALL_SECTIONS=(preflight brew links mise herdr-plugins tmux nvim agent-stack shell)

show_help() {
    cat <<'EOF'
install-mac — provision a macOS workstation with these dotfiles and tools

Usage: ./install-mac [OPTIONS]

Runs, in order:
  preflight       Darwin, Xcode Command Line Tools, Homebrew present
  brew            Homebrew bundle from mac/Brewfile (and apps with --apps)
  links           Dotfile links from mac/links.txt plus gh/herdr/gitconfig rules
  mise            mise trust, then mise install (never upgrade); --check probes missing tools
  herdr-plugins   Install only missing Herdr plugins from herdr/plugins.txt
  tmux            Clone TPM if missing, then run TPM install_plugins
  nvim            nvim --headless '+Lazy! sync' +qa
  agent-stack     ./install-agent-stack (default; skip with --skip agent-stack)
  shell           Only with --fish-shell, add brew fish to /etc/shells and chsh

Options:
  --dry-run             Print planned changes without changing anything
  --check               Read-only check; exits 2 when drift is found
  --only a,b            Run only the named sections
  --skip a,b            Skip the named sections
  --apps                Include mac/Brewfile.apps casks in the brew section
  --drift               Read-only Homebrew drift report and exit
  --adopt-gitconfig     Move an existing ~/.gitconfig to ~/.gitconfig.local,
                        backing up any existing local file, then link repo config
  --fish-shell          Offer to make Homebrew fish the login shell
  --yes, -y             Do not prompt for confirmation
  --help, -h            Show this help

Exit codes: 0 ok, 1 a section failed, 2 drift under --check, 64 usage.
EOF
}

valid_section() {
    local wanted="$1" section
    for section in "${ALL_SECTIONS[@]}"; do
        [ "$wanted" = "$section" ] && return 0
    done
    return 1
}

validate_section_list() {
    local list="$1" item old_ifs
    [ -n "$list" ] || return 0
    old_ifs=$IFS
    IFS=,
    # shellcheck disable=SC2086 # intentional word splitting on comma-separated sections
    set -- $list
    IFS=$old_ifs
    for item in "$@"; do
        [ -n "$item" ] || usage_error "empty section name in '$list'"
        valid_section "$item" || usage_error "unknown section '$item'"
    done
}

list_contains() {
    local list="$1" wanted="$2" item old_ifs
    [ -n "$list" ] || return 1
    old_ifs=$IFS
    IFS=,
    # shellcheck disable=SC2086 # intentional word splitting on comma-separated sections
    set -- $list
    IFS=$old_ifs
    for item in "$@"; do
        [ "$item" = "$wanted" ] && return 0
    done
    return 1
}

selected_section() {
    local section_name="$1"
    if [ -n "$ONLY_SECTIONS" ] && ! list_contains "$ONLY_SECTIONS" "$section_name"; then
        return 1
    fi
    if list_contains "$SKIP_SECTIONS" "$section_name"; then
        return 1
    fi
    return 0
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            --check)
                CHECK_MODE=true
                ;;
            --only)
                [ "$#" -gt 1 ] || usage_error "--only needs a comma-separated list"
                ONLY_SECTIONS="$2"
                shift
                ;;
            --only=*)
                ONLY_SECTIONS="${1#--only=}"
                ;;
            --skip)
                [ "$#" -gt 1 ] || usage_error "--skip needs a comma-separated list"
                SKIP_SECTIONS="$2"
                shift
                ;;
            --skip=*)
                SKIP_SECTIONS="${1#--skip=}"
                ;;
            --apps)
                INSTALL_APPS=true
                ;;
            --drift)
                DRIFT_MODE=true
                ;;
            --adopt-gitconfig)
                ADOPT_GITCONFIG=true
                ;;
            --fish-shell)
                SET_FISH_SHELL=true
                ;;
            --yes|-y)
                ASSUME_YES=true
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                usage_error "unknown option '$1'"
                ;;
        esac
        shift
    done

    validate_section_list "$ONLY_SECTIONS"
    validate_section_list "$SKIP_SECTIONS"

    if $DRY_RUN && $CHECK_MODE; then
        usage_error "--dry-run and --check are mutually exclusive"
    fi
}

summary_and_exit() {
    printf '\nsummary changes=%s warnings=%s failed=%s drift=%s\n' \
        "$CHANGES" "$WARNINGS" "$FAILED" "$DRIFT"
    # A failure is more important than drift, even under --check.
    if [ "$FAILED" -ne 0 ]; then
        exit 1
    fi
    if $CHECK_MODE && [ "$DRIFT" -ne 0 ]; then
        exit 2
    fi
    exit 0
}

backup_dir() {
    local base suffix candidate
    if [ -z "$BACKUP_DIR" ]; then
        base="$HOME/.dotfiles-backup/$(date '+%Y%m%d-%H%M%S')"
        candidate="$base"
        suffix=1
        while [ -e "$candidate" ]; do
            candidate="$base-$suffix"
            suffix=$((suffix + 1))
        done
        mkdir -p "$candidate" || return 1
        BACKUP_DIR="$candidate"
    fi
}

backup_path() {
    local target="$1" rel dest root suffix base_dest dest_parent
    rel="${target#"$HOME"/}"
    if [ "$rel" = "$target" ]; then
        rel="$(basename "$target")"
    fi
    # Not in a subshell: backup_dir sets BACKUP_DIR once for the whole run.
    if backup_dir; then
        root="$BACKUP_DIR"
    else
        fail "failed to create backup directory under $(pretty_path "$HOME/.dotfiles-backup")"
        return 1
    fi
    dest="$root/$rel"
    base_dest="$dest"
    suffix=1
    while [ -e "$dest" ] || [ -L "$dest" ]; do
        dest="$base_dest.$suffix"
        suffix=$((suffix + 1))
    done
    dest_parent="$(dirname "$dest")"
    if ! mkdir -p "$dest_parent"; then
        fail "failed to create backup parent $(pretty_path "$dest_parent")"
        return 1
    fi
    if ! mv "$target" "$dest"; then
        fail "failed to back up $(pretty_path "$target") to $(pretty_path "$dest")"
        return 1
    fi
    warn "backed up $(pretty_path "$target") to $(pretty_path "$dest")"
}

plan_or_backup() {
    local target="$1"
    if $DRY_RUN || $CHECK_MODE; then
        change "would back up $(pretty_path "$target")"
        return 0
    fi
    backup_path "$target"
}

plan_or_remove() {
    local target="$1" description="$2"
    if $DRY_RUN || $CHECK_MODE; then
        change "would remove $description"
        return 0
    fi
    if ! rm -f "$target"; then
        fail "failed to remove $description"
        return 1
    fi
    change "removed $description"
}

ensure_real_parent_dirs() {
    local target="$1" parent current rel prefix
    parent="$(dirname "$target")"
    case "$parent" in
        "$HOME"|"$HOME"/*) ;;
        *)
            mkdir -p "$parent" || { fail "failed to create directory $(pretty_path "$parent")"; return 1; }
            return 0
            ;;
    esac

    rel="${parent#"$HOME"/}"
    [ "$rel" != "$parent" ] || return 0
    prefix="$HOME"
    while [ -n "$rel" ]; do
        current="$prefix/${rel%%/*}"
        if [ -L "$current" ] && points_into_dotfiles "$current"; then
            if $DRY_RUN || $CHECK_MODE; then
                change "would convert repo symlink parent $(pretty_path "$current") to a real directory"
                return 0
            fi
            backup_path "$current" || return 1
            mkdir -p "$current" || { fail "failed to create directory $(pretty_path "$current")"; return 1; }
            change "converted repo symlink parent $(pretty_path "$current") to a real directory"
        elif [ ! -e "$current" ]; then
            if $DRY_RUN || $CHECK_MODE; then
                change "would create directory $(pretty_path "$current")"
                return 0
            fi
            mkdir -p "$current" || { fail "failed to create directory $(pretty_path "$current")"; return 1; }
            change "created directory $(pretty_path "$current")"
        elif [ ! -d "$current" ]; then
            plan_or_backup "$current" || return 1
            if ! $DRY_RUN && ! $CHECK_MODE; then
                mkdir -p "$current" || { fail "failed to create directory $(pretty_path "$current")"; return 1; }
                change "created directory $(pretty_path "$current")"
            fi
        fi

        if [ "$rel" = "${rel#*/}" ]; then
            break
        fi
        prefix="$current"
        rel="${rel#*/}"
    done
}

ensure_real_dir() {
    local dir="$1"
    ensure_real_parent_dirs "$dir" || return 1

    if [ -d "$dir" ] && [ ! -L "$dir" ]; then
        ok "real directory: $(pretty_path "$dir")"
        return 0
    fi

    if [ -e "$dir" ] || [ -L "$dir" ]; then
        plan_or_backup "$dir" || return 1
    fi

    if $DRY_RUN || $CHECK_MODE; then
        change "would create real directory $(pretty_path "$dir")"
        return 0
    fi

    mkdir -p "$dir" || { fail "failed to create real directory $(pretty_path "$dir")"; return 1; }
    change "created real directory $(pretty_path "$dir")"
}

is_correct_link() {
    local source="$1" target="$2"
    [ -L "$target" ] || return 1
    [ -e "$source" ] || return 1
    same_resolved_path "$target" "$source"
}

link_config() {
    local source_rel="$1" target_raw="$2" mode="${3:-link}" source target
    target="$(expand_home_path "$target_raw")"

    if $HERDR_REPAIR_DEFERRED; then
        case "$target" in
            "$HOME/.config/herdr"|"$HOME/.config/herdr"/*)
                ok "skipping Herdr link while server is running: $(pretty_path "$target")"
                return 0
                ;;
        esac
    fi

    if [ "$mode" = "realdir" ]; then
        ensure_real_dir "$target"
        return $?
    fi

    source="$DOTFILES_DIR/$source_rel"
    if [ ! -e "$source" ]; then
        if [ "$mode" = "optional" ]; then
            ok "optional source missing: $source_rel"
            return 0
        fi
        fail "missing source in repo: $source_rel"
        return 1
    fi

    ensure_real_parent_dirs "$target" || return 1

    if [ "$mode" = "link-if-absent" ] && { [ -e "$target" ] || [ -L "$target" ]; }; then
        if is_correct_link "$source" "$target"; then
            ok "already linked: $(pretty_path "$target")"
        else
            ok "left existing path alone: $(pretty_path "$target")"
        fi
        return 0
    fi

    if is_correct_link "$source" "$target"; then
        ok "already linked: $(pretty_path "$target") -> $source_rel"
        return 0
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        plan_or_backup "$target" || return 1
    fi

    if $DRY_RUN || $CHECK_MODE; then
        change "would link $(pretty_path "$target") -> $source_rel"
        return 0
    fi

    mkdir -p "$(dirname "$target")" || { fail "failed to create directory $(pretty_path "$(dirname "$target")")"; return 1; }
    ln -s "$source" "$target" || { fail "failed to link $(pretty_path "$target") -> $source_rel"; return 1; }
    change "linked $(pretty_path "$target") -> $source_rel"
}

process_links_manifest() {
    local line source target mode status old_flags
    [ -f "$LINKS_FILE" ] || { fail "missing links manifest: $LINKS_FILE"; return 1; }
    status=0

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        old_flags="$-"
        set -f
        # shellcheck disable=SC2086 # manifest fields are intentionally whitespace-separated
        set -- $line
        case "$old_flags" in
            *f*) ;;
            *) set +f ;;
        esac
        [ "$#" -eq 0 ] && continue
        if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
            fail "invalid links manifest line: $line"
            status=1
            continue
        fi
        source="$1"
        target="$2"
        mode="${3:-link}"
        case "$mode" in
            link|realdir|link-if-absent|optional) ;;
            *)
                fail "invalid link mode '$mode' for $target"
                status=1
                continue
                ;;
        esac
        if ! link_config "$source" "$target" "$mode"; then
            status=1
        fi
    done <"$LINKS_FILE"
    return "$status"
}

herdr_server_running() {
    pgrep -u "$(id -u)" -x herdr >/dev/null 2>&1
}

repair_herdr_symlink_dir() {
    local dir="$HOME/.config/herdr" source_dir socket_count runtime_file plugins_dir
    [ -L "$dir" ] && points_into_dotfiles "$dir" || return 0
    source_dir="$(link_target_path "$dir")"

    socket_count="$(find "$source_dir" -maxdepth 1 \( -type s -o -name '*.sock' \) -print 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$socket_count" != "0" ]; then
        if herdr_server_running; then
            warn "Herdr socket files found and a herdr process is running; stop Herdr and re-run to convert $(pretty_path "$dir") safely"
            HERDR_REPAIR_DEFERRED=true
            if $CHECK_MODE; then
                DRIFT=1
            fi
            return 0
        fi
        warn "Herdr socket files found in repo copy; treating them as stale because no herdr process is running"
    fi

    if $DRY_RUN || $CHECK_MODE; then
        change "would convert $(pretty_path "$dir") from a repo symlink to a real directory"
        return 0
    fi

    backup_path "$dir" || return 1
    mkdir -p "$dir" || { fail "failed to create real Herdr config directory $(pretty_path "$dir")"; return 1; }
    for runtime_file in session.json release-notes.json .plugins.lock plugins.json sessions; do
        if [ -e "$source_dir/$runtime_file" ]; then
            mv "$source_dir/$runtime_file" "$dir/$runtime_file" || { fail "failed to move Herdr runtime path $runtime_file into real config dir"; return 1; }
            change "moved Herdr runtime path $runtime_file into real config dir"
        fi
    done
    plugins_dir="$source_dir/plugins"
    if [ -e "$plugins_dir" ]; then
        mv "$plugins_dir" "$dir/plugins" || { fail "failed to move Herdr plugins directory into real config dir"; return 1; }
        change "moved Herdr plugins directory into real config dir"
    fi
    for runtime_file in "$source_dir"/*.log; do
        [ -e "$runtime_file" ] || continue
        mv "$runtime_file" "$dir/$(basename "$runtime_file")" || { fail "failed to move Herdr runtime file $(basename "$runtime_file") into real config dir"; return 1; }
        change "moved Herdr runtime file $(basename "$runtime_file") into real config dir"
    done
    if ! find "$source_dir" -maxdepth 1 \( -type s -o -name '*.sock' \) -exec rm -f {} + 2>/dev/null; then
        fail "failed to remove stale Herdr socket files from repo copy"
        return 1
    fi
    change "converted $(pretty_path "$dir") to a real Herdr config directory"
}

recover_gh_hosts_from_history() {
    local destination="$1" delete_commit tmp_destination
    have git || return 1
    git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
    delete_commit="$(git -C "$DOTFILES_DIR" log -n 1 --diff-filter=D --format=%H -- gh/hosts.yml 2>/dev/null || true)"
    [ -n "$delete_commit" ] || return 1
    tmp_destination="$destination.tmp.$$"
    if ! (umask 077 && git -C "$DOTFILES_DIR" show "$delete_commit^:gh/hosts.yml" >"$tmp_destination" 2>/dev/null); then
        rm -f "$tmp_destination"
        return 1
    fi
    mv "$tmp_destination" "$destination" || { rm -f "$tmp_destination"; return 1; }
    chmod 600 "$destination" 2>/dev/null || true
}

repair_gh_symlink_dir() {
    local dir="$HOME/.config/gh" source_dir
    [ -L "$dir" ] && points_into_dotfiles "$dir" || return 0
    source_dir="$(link_target_path "$dir")"

    if $DRY_RUN || $CHECK_MODE; then
        change "would convert $(pretty_path "$dir") from a repo symlink to a real directory and preserve hosts.yml"
        return 0
    fi

    backup_path "$dir" || return 1
    mkdir -p "$dir" || { fail "failed to create real gh config directory $(pretty_path "$dir")"; return 1; }
    if [ -e "$source_dir/hosts.yml" ]; then
        cp -p "$source_dir/hosts.yml" "$dir/hosts.yml" || { fail "failed to copy gh hosts.yml into real config dir"; return 1; }
        chmod 600 "$dir/hosts.yml" 2>/dev/null || warn "failed to chmod gh hosts.yml to 600"
        change "copied gh hosts.yml into real config dir"
    elif recover_gh_hosts_from_history "$dir/hosts.yml"; then
        change "recovered gh hosts.yml from git history into real config dir"
    else
        warn "gh hosts.yml was not found in the repo copy or git history; run 'gh auth login' if gh is logged out"
    fi
    change "converted $(pretty_path "$dir") to a real gh config directory"
}

cleanup_ghostty_dangling_link() {
    local target="$HOME/.config/ghostty"
    [ -L "$target" ] || return 0
    [ ! -e "$target" ] || return 0
    points_into_dotfiles "$target" || return 0
    plan_or_remove "$target" "dangling Ghostty link $(pretty_path "$target")"
}

install_gitconfig() {
    local target="$HOME/.gitconfig" source="$DOTFILES_DIR/gitconfig" local_config="$HOME/.gitconfig.local"

    [ -e "$source" ] || { fail "missing source in repo: gitconfig"; return 1; }

    if is_correct_link "$source" "$target"; then
        ok "already linked: $(pretty_path "$target") -> gitconfig"
        if [ ! -e "$local_config" ] && [ ! -L "$local_config" ]; then
            warn "$(pretty_path "$local_config") is missing; machine-local git settings such as signing keys and credential helpers will not override repo defaults"
        fi
        return 0
    fi

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        if $DRY_RUN || $CHECK_MODE; then
            change "would link $(pretty_path "$target") -> gitconfig"
            return 0
        fi
        ln -s "$source" "$target" || { fail "failed to link $(pretty_path "$target") -> gitconfig"; return 1; }
        change "linked $(pretty_path "$target") -> gitconfig"
        return 0
    fi

    if [ -f "$target" ] && [ ! -L "$target" ]; then
        if ! $ADOPT_GITCONFIG; then
            warn "gitconfig drift: $(pretty_path "$target") is a real file; use --adopt-gitconfig to move it to ~/.gitconfig.local"
            if $CHECK_MODE; then
                DRIFT=1
            fi
            return 0
        fi

        if $DRY_RUN || $CHECK_MODE; then
            change "would move $(pretty_path "$target") to $(pretty_path "$local_config") and link repo gitconfig"
            return 0
        fi

        if [ -e "$local_config" ] || [ -L "$local_config" ]; then
            backup_path "$local_config" || return 1
        fi
        mv "$target" "$local_config" || { fail "failed to move $(pretty_path "$target") to $(pretty_path "$local_config")"; return 1; }
        ln -s "$source" "$target" || { fail "failed to link $(pretty_path "$target") -> gitconfig"; return 1; }
        change "adopted existing gitconfig as $(pretty_path "$local_config") and linked repo gitconfig"
        return 0
    fi

    warn "gitconfig drift: $(pretty_path "$target") is not the expected link; leaving it unchanged"
    if $CHECK_MODE; then
        DRIFT=1
    fi
}

install_links() {
    section "links"
    ensure_real_dir "$HOME/.config"
    ensure_real_dir "$HOME/.local/bin"
    repair_herdr_symlink_dir
    repair_gh_symlink_dir
    cleanup_ghostty_dangling_link
    install_gitconfig
    process_links_manifest
}

preflight() {
    section "preflight"
    if [ "$(uname -s)" != "Darwin" ]; then
        fail "install-mac runs only on macOS (Darwin)"
        return 1
    fi
    ok "Darwin host"

    if ! xcode-select -p >/dev/null 2>&1; then
        fail "Xcode Command Line Tools are missing; run: xcode-select --install"
        return 1
    fi
    ok "Xcode Command Line Tools present"

    if ! have brew; then
        fail "Homebrew is missing; install it from https://brew.sh/ and re-run (this script will not curl-install it)"
        return 1
    fi
    ok "Homebrew present: $(command -v brew)"
}

brew_bundle_env() {
    HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_NO_INSTALL_CLEANUP=1 \
    HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 \
        brew "$@"
}

brew_bundle() {
    local file="$1" label="$2"
    if brew_bundle_env bundle check --no-upgrade --file="$file" >/dev/null 2>&1; then
        ok "brew bundle satisfied: $label"
        return 0
    fi

    if $CHECK_MODE; then
        change "brew bundle drift: $label"
        return 0
    fi
    if $DRY_RUN; then
        change "would run brew bundle install --file=$file --no-upgrade"
        return 0
    fi

    if brew_bundle_env bundle install --file="$file" --no-upgrade; then
        change "installed missing Homebrew items from $label"
    else
        fail "brew bundle install failed: $label"
        return 1
    fi
}

install_brew() {
    section "brew"
    have brew || { fail "brew not found on PATH"; return 1; }
    brew_bundle "$MAC_DIR/Brewfile" "mac/Brewfile"
    if $INSTALL_APPS; then
        brew_bundle "$MAC_DIR/Brewfile.apps" "mac/Brewfile.apps"
    else
        ok "app casks skipped (pass --apps to include mac/Brewfile.apps)"
    fi
}

brewfile_items() {
    local file="$1"
    awk '
        /^[[:space:]]*(tap|brew|cask)[[:space:]]+"/ {
            line=$0
            sub(/^[[:space:]]*(tap|brew|cask)[[:space:]]+"/, "", line)
            sub(/".*/, "", line)
            print line
        }
    ' "$file"
}

brew_drift() {
    local current tmp desired_file current_file
    section "brew drift"
    have brew || { fail "brew not found on PATH"; return 1; }
    tmp="$(mktemp -d)"
    desired_file="$tmp/desired"
    current_file="$tmp/current"
    {
        brewfile_items "$MAC_DIR/Brewfile"
        brewfile_items "$MAC_DIR/Brewfile.apps"
    } | sort -u >"$desired_file"

    if current="$(brew_bundle_env bundle dump --file=- --force 2>/dev/null)"; then
        printf '%s\n' "$current" | awk '
            /^[[:space:]]*(tap|brew|cask)[[:space:]]+"/ {
                line=$0
                sub(/^[[:space:]]*(tap|brew|cask)[[:space:]]+"/, "", line)
                sub(/".*/, "", line)
                print line
            }
        ' | sort -u >"$current_file"
    else
        {
            brew_bundle_env tap 2>/dev/null || true
            brew_bundle_env leaves 2>/dev/null || true
            brew_bundle_env list --cask 2>/dev/null || true
        } | sort -u >"$current_file"
    fi

    if diff -u "$desired_file" "$current_file"; then
        ok "Homebrew state matches curated Brewfiles"
    else
        warn "Homebrew drift shown above; curate mac/Brewfile or mac/Brewfile.apps if intentional"
    fi
    rm -rf "$tmp"
}

add_mise_shims_to_path() {
    local shims="$HOME/.local/share/mise/shims"
    case ":$PATH:" in
        *":$shims:"*) ;;
        *)
            PATH="$shims:$PATH"
            export PATH
            ;;
    esac
}

install_mise_tools() {
    section "mise"
    have mise || { fail "mise not found on PATH after Homebrew section"; return 1; }
    if $DRY_RUN; then
        change "would run mise trust $DOTFILES_DIR/mise/config.toml"
        change "would run mise install -C $HOME"
        return 0
    fi
    if $CHECK_MODE; then
        local missing
        if missing="$(mise ls --missing --no-header -C "$HOME" 2>/dev/null)"; then
            if [ -n "$missing" ]; then
                change "mise tool drift: missing tools from mise/config.toml"
                printf '%s\n' "$missing" | sed 's/^/  /'
            else
                ok "mise tools satisfied"
            fi
        else
            fail "mise missing-tool probe failed (is mise/config.toml trusted?)"
            return 1
        fi
        return 0
    fi
    if mise trust "$DOTFILES_DIR/mise/config.toml" && mise install -C "$HOME"; then
        add_mise_shims_to_path
        change "mise tools installed from trusted config"
    else
        fail "mise install failed"
        return 1
    fi
}

herdr_plugin_id() {
    case "$1" in
        paulbkim-dev/vim-herdr-navigation) printf 'vim-herdr-navigation\n' ;;
        JanTvrdik/herdr-command-palette) printf 'jt.command-palette\n' ;;
        rmarganti/herdr-pluck) printf 'rmarganti.herdr-pluck\n' ;;
        Tyru5/herdr-floax) printf 'herdr-floax\n' ;;
        thanhdat77/herdr-navigator) printf 'herdr-navigator\n' ;;
        iurysza/termscope) printf 'termscope\n' ;;
        *) printf '%s\n' "${1##*/}" ;;
    esac
}

herdr_installed_plugin_ids() {
    awk '/^- / { print $2 }'
}

install_herdr_plugins() {
    local plugin plugin_id installed installed_ids plugins_file="$DOTFILES_DIR/herdr/plugins.txt"
    section "herdr-plugins"
    [ -f "$plugins_file" ] || { fail "missing Herdr plugin manifest: herdr/plugins.txt"; return 1; }
    have herdr || { warn "herdr not found on PATH; skipping Herdr plugins"; return 0; }

    if ! installed="$(herdr plugin list 2>/dev/null)"; then
        fail "herdr plugin list failed"
        return 1
    fi
    installed_ids="$(printf '%s\n' "$installed" | herdr_installed_plugin_ids)"

    if printf '%s\n' "$installed_ids" | grep -Fx -q herdr-picker-plus; then
        if $DRY_RUN || $CHECK_MODE; then
            change "would uninstall legacy Herdr plugin herdr-picker-plus"
        elif herdr plugin uninstall herdr-picker-plus; then
            change "uninstalled legacy Herdr plugin herdr-picker-plus"
            installed_ids="$(printf '%s\n' "$installed_ids" | grep -Fx -v herdr-picker-plus || true)"
        else
            warn "failed to uninstall legacy Herdr plugin herdr-picker-plus"
        fi
    fi

    while IFS= read -r plugin || [ -n "$plugin" ]; do
        plugin="${plugin%%#*}"
        set -f
        # shellcheck disable=SC2086 # plugin ids do not contain shell whitespace
        set -- $plugin
        set +f
        [ "$#" -eq 0 ] && continue
        plugin="$1"
        plugin_id="$(herdr_plugin_id "$plugin")"
        if printf '%s\n' "$installed_ids" | grep -Fx -q "$plugin_id"; then
            ok "Herdr plugin present: $plugin_id ($plugin)"
            continue
        fi
        if $DRY_RUN || $CHECK_MODE; then
            change "would install Herdr plugin $plugin"
            continue
        fi
        if herdr plugin install "$plugin" --yes; then
            change "installed Herdr plugin $plugin"
        else
            fail "failed to install Herdr plugin $plugin"
        fi
    done <"$plugins_file"
}

install_tmux_plugins() {
    local tpm_dir="$HOME/.config/tmux/plugins/tpm" legacy_dir="$HOME/.tmux/plugins/tpm" install_script="$HOME/.config/tmux/plugins/tpm/bin/install_plugins"
    section "tmux"
    if [ ! -d "$tpm_dir" ]; then
        if $DRY_RUN || $CHECK_MODE; then
            change "would clone TPM into $(pretty_path "$tpm_dir")"
            return 0
        fi
        mkdir -p "$(dirname "$tpm_dir")" || { fail "failed to create directory $(pretty_path "$(dirname "$tpm_dir")")"; return 1; }
        if git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"; then
            change "cloned TPM"
        else
            fail "failed to clone TPM"
            return 1
        fi
    else
        ok "TPM present"
    fi

    if [ -L "$legacy_dir" ] && [ ! -e "$legacy_dir" ]; then
        plan_or_backup "$legacy_dir" || return 1
    fi

    if [ ! -e "$legacy_dir" ] && [ ! -L "$legacy_dir" ]; then
        if $DRY_RUN || $CHECK_MODE; then
            change "would link legacy TPM path $(pretty_path "$legacy_dir") -> $(pretty_path "$tpm_dir")"
            return 0
        fi
        mkdir -p "$(dirname "$legacy_dir")" || { fail "failed to create directory $(pretty_path "$(dirname "$legacy_dir")")"; return 1; }
        ln -s "$tpm_dir" "$legacy_dir" || { fail "failed to link legacy TPM path"; return 1; }
        change "linked legacy TPM path"
    fi

    if [ ! -x "$install_script" ]; then
        warn "TPM install script missing or not executable: $(pretty_path "$install_script")"
        return 0
    fi
    if $DRY_RUN; then
        change "would run TPM install_plugins"
        return 0
    fi
    if $CHECK_MODE; then
        ok "TPM install_plugins not run under --check"
        return 0
    fi
    if "$install_script"; then
        change "ran TPM install_plugins"
    else
        fail "TPM install_plugins failed"
        return 1
    fi
}

sync_nvim() {
    section "nvim"
    have nvim || { warn "nvim not found on PATH; skipping Lazy sync"; return 0; }
    if $DRY_RUN; then
        change "would run nvim --headless '+Lazy! sync' +qa"
        return 0
    fi
    if $CHECK_MODE; then
        ok "Neovim Lazy sync not run under --check"
        return 0
    fi
    if nvim --headless '+Lazy! sync' +qa; then
        change "synced Neovim plugins"
    else
        fail "Neovim Lazy sync failed"
        return 1
    fi
}

install_agent_stack() {
    section "agent-stack"
    if [ ! -x "$DOTFILES_DIR/install-agent-stack" ]; then
        warn "install-agent-stack entry point not executable; skipping"
        return 0
    fi
    if $DRY_RUN; then
        change "would run ./install-agent-stack"
        return 0
    fi
    if $CHECK_MODE; then
        ok "install-agent-stack not run under --check"
        return 0
    fi
    if "$DOTFILES_DIR/install-agent-stack"; then
        change "installed agent stack"
    else
        fail "install-agent-stack failed"
        return 1
    fi
}

confirm() {
    local prompt="$1" reply
    $ASSUME_YES && return 0
    printf '%s [y/N] ' "$prompt"
    read -r reply
    case "$reply" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

configure_fish_shell() {
    local fish_path
    section "shell"
    if ! $SET_FISH_SHELL; then
        ok "fish shell change skipped (pass --fish-shell to opt in)"
        return 0
    fi
    have brew || { fail "brew not found on PATH"; return 1; }
    fish_path="$(brew --prefix fish 2>/dev/null)/bin/fish"
    [ -x "$fish_path" ] || { fail "Homebrew fish not found at $fish_path"; return 1; }

    if ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
        if $DRY_RUN || $CHECK_MODE; then
            change "would add $fish_path to /etc/shells"
        elif confirm "Add $fish_path to /etc/shells with sudo?"; then
            if printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null; then
                change "added $fish_path to /etc/shells"
            else
                fail "failed to add $fish_path to /etc/shells"
                return 1
            fi
        else
            warn "fish shell change declined"
            return 0
        fi
    else
        ok "$fish_path already in /etc/shells"
    fi

    if [ "${SHELL:-}" = "$fish_path" ]; then
        ok "login shell already $fish_path"
        return 0
    fi
    if $DRY_RUN || $CHECK_MODE; then
        change "would run chsh -s $fish_path"
    elif confirm "Change login shell to $fish_path?"; then
        if chsh -s "$fish_path"; then
            change "changed login shell to $fish_path"
        else
            fail "failed to change login shell to $fish_path"
            return 1
        fi
    else
        warn "fish shell change declined"
    fi
}

run_section() {
    local section_name="$1"
    selected_section "$section_name" || { ok "skipping section: $section_name"; return 0; }
    case "$section_name" in
        preflight) preflight ;;
        brew) install_brew ;;
        links) install_links ;;
        mise) install_mise_tools ;;
        herdr-plugins) install_herdr_plugins ;;
        tmux) install_tmux_plugins ;;
        nvim) sync_nvim ;;
        agent-stack) install_agent_stack ;;
        shell) configure_fish_shell ;;
        *) usage_error "unknown section '$section_name'" ;;
    esac
}

main() {
    local section_name section_status
    parse_args "$@"

    if $DRIFT_MODE; then
        set +e
        brew_drift
        section_status=$?
        set -e
        [ "$section_status" -eq 0 ] || FAILED=1
        summary_and_exit
    fi

    for section_name in "${ALL_SECTIONS[@]}"; do
        set +e
        run_section "$section_name"
        section_status=$?
        set -e
        [ "$section_status" -eq 0 ] || FAILED=1
        if [ "$section_name" = preflight ] && selected_section preflight && [ "$FAILED" -ne 0 ]; then
            summary_and_exit
        fi
    done

    summary_and_exit
}

main "$@"
