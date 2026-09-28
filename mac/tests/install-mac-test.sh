#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORIGINAL_HOME="${HOME:-}"

fail_test() {
    printf 'not ok %s\n' "$*" >&2
    exit 1
}

assert_exists() { [ -e "$1" ] || fail_test "expected path to exist: $1"; }
assert_not_exists() { [ ! -e "$1" ] && [ ! -L "$1" ] || fail_test "expected path to be absent: $1"; }
assert_file_contains() { grep -F -q "$2" "$1" || fail_test "expected $1 to contain $2"; }
assert_symlink_to() {
    local link="$1" target="$2"
    [ -L "$link" ] || fail_test "expected symlink: $link"
    [ "$(cd -P "$(dirname "$link")" && cd -P "$(dirname "$(readlink "$link")")" 2>/dev/null && pwd)/$(basename "$(readlink "$link")")" = \
      "$(cd -P "$(dirname "$target")" && pwd)/$(basename "$target")" ] || \
        fail_test "expected $link to resolve to $target, got $(readlink "$link")"
}

snapshot_tree() {
    local dir="$1" path
    (
        cd "$dir"
        find . -mindepth 1 -print | sort | while IFS= read -r path; do
            if [ -L "$path" ]; then
                printf 'L %s -> %s\n' "$path" "$(readlink "$path")"
            elif [ -d "$path" ]; then
                printf 'D %s\n' "$path"
            elif [ -f "$path" ]; then
                printf 'F %s %s\n' "$path" "$(shasum -a 256 "$path" | awk '{print $1}')"
            else
                printf '? %s\n' "$path"
            fi
        done
    )
}

snapshot_real_home() {
    local rel path
    [ -n "$ORIGINAL_HOME" ] || return 0
    for rel in \
        .gitconfig \
        .gitconfig.local \
        .dotfiles-backup \
        .config/gh \
        .config/gh/config.yml \
        .config/gh/hosts.yml \
        .config/herdr \
        .config/herdr/config.toml \
        .config/herdr/scripts \
        .config/herdr/.plugins.lock \
        .config/herdr/plugins \
        .config/herdr/plugins.json \
        .config/herdr/sessions \
        .tmux/plugins/tpm \
        .local/bin/tmux-background-install-indicator.sh \
        .local/bin/herdr-fish; do
        path="$ORIGINAL_HOME/$rel"
        if [ -L "$path" ]; then
            printf 'L %s -> %s\n' "$rel" "$(readlink "$path")"
        elif [ -f "$path" ]; then
            printf 'F %s %s\n' "$rel" "$(shasum -a 256 "$path" | awk '{print $1}')"
        elif [ -d "$path" ]; then
            printf 'D %s\n' "$rel"
        else
            printf 'A %s\n' "$rel"
        fi
    done
}

setup_repo() {
    local tmp="$1" repo
    repo="$tmp/repo"
    mkdir -p "$repo"
    cp "$ROOT/install-mac" "$repo/install-mac"
    chmod +x "$repo/install-mac"
    cat >"$repo/install-agent-stack" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'agent-stack\n' >>"$FAKE_LOG"
EOF
    chmod +x "$repo/install-agent-stack"
    mkdir -p "$repo/mac"
    cp "$ROOT/mac/install.sh" "$repo/mac/install.sh"
    chmod +x "$repo/mac/install.sh"
    cp -R "$ROOT/mac/lib" "$repo/mac/lib"
    cp "$ROOT/mac/links.txt" "$repo/mac/links.txt"
    cp "$ROOT/mac/Brewfile" "$repo/mac/Brewfile"
    cp "$ROOT/mac/Brewfile.apps" "$repo/mac/Brewfile.apps"
    cp "$ROOT/gitconfig" "$repo/gitconfig"
    cp "$ROOT/gitignore_local" "$repo/gitignore_local"
    cp "$ROOT/vale.ini" "$repo/vale.ini"
    mkdir -p "$repo/herdr" "$repo/gh" "$repo/gh-dash" "$repo/gopod" "$repo/scripts" "$repo/mise"
    printf 'repo gh config\n' >"$repo/gh/config.yml"
    printf 'repo gh-dash config\n' >"$repo/gh-dash/config.yml"
    printf 'repo gopod config\n' >"$repo/gopod/config.json"
    printf 'repo herdr config\n' >"$repo/herdr/config.toml"
    mkdir -p "$repo/herdr/scripts"
    printf 'indicator\n' >"$repo/scripts/tmux-background-install-indicator.sh"
    printf 'mise\n' >"$repo/mise/config.toml"
    printf '%s\n' "$repo"
}

run_install() {
    local repo="$1" home="$2" manifest="$3"
    shift 3
    HOME="$home" INSTALL_MAC_LINKS_FILE="$manifest" "$repo/install-mac" --only links "$@"
}

test_link_states() {
    local tmp repo home manifest out backup_count status
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/links.txt"
    mkdir -p "$home/.config" "$repo/src" "$repo/parent" "$repo/existing-dir"
    printf 'correct\n' >"$repo/src/correct"
    printf 'missing\n' >"$repo/src/missing"
    printf 'wrong\n' >"$repo/src/wrong"
    printf 'wrong-old\n' >"$repo/src/wrong-old"
    printf 'dangling\n' >"$repo/src/dangling"
    printf 'realfile\n' >"$repo/src/realfile"
    mkdir -p "$repo/src/realdir"
    printf 'child\n' >"$repo/src/parent-child"
    printf 'ifmissing\n' >"$repo/src/ifmissing"
    printf 'ifexists\n' >"$repo/src/ifexists"

    ln -s "../../repo/src/correct" "$home/.config/correct"
    ln -s "$repo/src/wrong-old" "$home/.config/wrong"
    ln -s "$repo/src/nope" "$home/.config/dangling"
    printf 'user data\n' >"$home/.config/realfile"
    mkdir -p "$home/.config/realdir"
    printf 'dir data\n' >"$home/.config/realdir/file"
    ln -s "$repo/parent" "$home/.config/parent"
    printf 'keep me\n' >"$home/.config/ifexists"
    ln -s "$repo/existing-dir" "$home/.config/real-parent"
    ln -s "$repo/ghostty" "$home/.config/ghostty"

    cat >"$manifest" <<EOF
src/correct ~/.config/correct
src/missing ~/.config/missing
src/wrong ~/.config/wrong
src/dangling ~/.config/dangling
src/realfile ~/.config/realfile
src/realdir ~/.config/realdir
src/parent-child ~/.config/parent/child
src/ifmissing ~/.config/ifmissing link-if-absent
src/ifexists ~/.config/ifexists link-if-absent
missing/source ~/.config/optional optional
- ~/.config/real-parent realdir
EOF

    out="$(run_install "$repo" "$home" "$manifest")"
    printf '%s\n' "$out" | grep -F -q 'already linked: ~/.config/correct' || fail_test 'correct relative link was not skipped'
    assert_symlink_to "$home/.config/missing" "$repo/src/missing"
    assert_symlink_to "$home/.config/wrong" "$repo/src/wrong"
    assert_symlink_to "$home/.config/dangling" "$repo/src/dangling"
    assert_symlink_to "$home/.config/realfile" "$repo/src/realfile"
    assert_symlink_to "$home/.config/realdir" "$repo/src/realdir"
    [ -d "$home/.config/parent" ] && [ ! -L "$home/.config/parent" ] || fail_test 'repo symlink parent was not converted to a real dir'
    assert_symlink_to "$home/.config/parent/child" "$repo/src/parent-child"
    assert_symlink_to "$home/.config/ifmissing" "$repo/src/ifmissing"
    assert_file_contains "$home/.config/ifexists" 'keep me'
    [ -d "$home/.config/real-parent" ] && [ ! -L "$home/.config/real-parent" ] || fail_test 'realdir did not become real dir'
    assert_not_exists "$home/.config/ghostty"
    [ -n "$(find "$home/.dotfiles-backup" -name ghostty -type l)" ] ||
        fail_test 'dangling Ghostty link was deleted instead of backed up'
    backup_count="$(find "$home/.dotfiles-backup" -type l -o -type f -o -type d | wc -l | tr -d ' ')"
    [ "$backup_count" -gt 0 ] || fail_test 'expected backups for replaced paths'
    [ "$(find "$home/.dotfiles-backup" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" -eq 1 ] ||
        fail_test 'all backups in one run should share a single timestamped directory'

    out="$(run_install "$repo" "$home" "$manifest")"
    ! printf '%s\n' "$out" | grep -q '^change ' || fail_test "second run should be a no-op, got: $out"

    set +e
    HOME="$home" INSTALL_MAC_LINKS_FILE="$manifest" "$repo/install-mac" --only links --check >/dev/null
    status=$?
    set -e
    [ "$status" -eq 0 ] || fail_test "clean links --check should exit 0, got $status"
    rm -rf "$tmp"
}

test_links_manifest_sources_exist() {
    local line source target mode old_flags missing=0
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
        source="$1"
        target="$2"
        mode="${3:-link}"
        [ "$source" != - ] || continue
        [ "$mode" != optional ] || continue
        if [ ! -e "$ROOT/$source" ]; then
            printf 'missing non-optional source for %s: %s\n' "$target" "$source" >&2
            missing=1
        fi
    done <"$ROOT/mac/links.txt"
    [ "$missing" -eq 0 ] || fail_test 'mac/links.txt has non-optional sources missing from repo'
}

test_ghostty_cleanup_negative_cases() {
    local tmp repo home manifest
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/empty-links.txt"
    mkdir -p "$home/.config" "$repo/ghostty"
    : >"$manifest"
    ln -s "$repo/ghostty" "$home/.config/ghostty"

    run_install "$repo" "$home" "$manifest" >/dev/null
    assert_symlink_to "$home/.config/ghostty" "$repo/ghostty"

    rm "$home/.config/ghostty"
    ln -s "$tmp/outside/missing-ghostty" "$home/.config/ghostty"
    run_install "$repo" "$home" "$manifest" >/dev/null
    [ -L "$home/.config/ghostty" ] || fail_test 'dangling Ghostty link outside repo was removed'
    [ "$(readlink "$home/.config/ghostty")" = "$tmp/outside/missing-ghostty" ] || fail_test 'dangling Ghostty link outside repo was changed'
    rm -rf "$tmp"
}

test_dry_run_and_check_are_read_only() {
    local tmp repo home manifest before after status
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/links.txt"
    mkdir -p "$home/.config" "$repo/src" "$repo/herdr/plugins"
    printf 'source\n' >"$repo/src/file"
    printf 'old\n' >"$home/.config/file"
    printf 'local gitconfig\n' >"$home/.gitconfig"
    printf 'hosts secret\n' >"$repo/gh/hosts.yml"
    printf 'session\n' >"$repo/herdr/session.json"
    printf 'lock\n' >"$repo/herdr/.plugins.lock"
    printf 'plugins registry\n' >"$repo/herdr/plugins.json"
    mkdir -p "$repo/herdr/sessions"
    printf 'saved session\n' >"$repo/herdr/sessions/session-one.json"
    printf 'plugin checkout\n' >"$repo/herdr/plugins/plugin"
    printf 'sock\n' >"$repo/herdr/stale.sock"
    ln -s "$repo/gh" "$home/.config/gh"
    ln -s "$repo/herdr" "$home/.config/herdr"
    cat >"$manifest" <<EOF
src/file ~/.config/file
- ~/.config/gh realdir
gh/config.yml ~/.config/gh/config.yml
- ~/.config/herdr realdir
herdr/config.toml ~/.config/herdr/config.toml
herdr/scripts ~/.config/herdr/scripts
EOF

    before="$(snapshot_tree "$home")"
    run_install "$repo" "$home" "$manifest" --dry-run --adopt-gitconfig >/dev/null
    after="$(snapshot_tree "$home")"
    [ "$before" = "$after" ] || fail_test '--dry-run changed HOME'

    set +e
    HOME="$home" INSTALL_MAC_LINKS_FILE="$manifest" "$repo/install-mac" --only links --check --adopt-gitconfig >/dev/null
    status=$?
    set -e
    [ "$status" -eq 2 ] || fail_test "--check with drift should exit 2, got $status"
    after="$(snapshot_tree "$home")"
    [ "$before" = "$after" ] || fail_test '--check changed HOME'
    rm -rf "$tmp"
}

test_gh_and_herdr_symlink_repairs() {
    local tmp repo home manifest bin
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/links.txt"
    bin="$tmp/bin"
    write_fake_bin "$bin"
    mkdir -p "$home/.config" "$repo/herdr/plugins"
    printf 'hosts secret\n' >"$repo/gh/hosts.yml"
    printf 'session\n' >"$repo/herdr/session.json"
    printf 'release\n' >"$repo/herdr/release-notes.json"
    printf 'lock\n' >"$repo/herdr/.plugins.lock"
    printf 'plugins registry\n' >"$repo/herdr/plugins.json"
    mkdir -p "$repo/herdr/sessions"
    printf 'saved session\n' >"$repo/herdr/sessions/session-one.json"
    printf 'log\n' >"$repo/herdr/herdr-server.log"
    printf 'plugin checkout\n' >"$repo/herdr/plugins/plugin"
    printf 'sock\n' >"$repo/herdr/stale.sock"
    ln -s "$repo/gh" "$home/.config/gh"
    ln -s "$repo/herdr" "$home/.config/herdr"
    cat >"$manifest" <<EOF
- ~/.config/gh realdir
gh/config.yml ~/.config/gh/config.yml
- ~/.config/herdr realdir
herdr/config.toml ~/.config/herdr/config.toml
herdr/scripts ~/.config/herdr/scripts
EOF

    FAKE_LOG="$tmp/fake.log" PATH="$bin:$PATH" run_install "$repo" "$home" "$manifest" >/dev/null
    [ -d "$home/.config/gh" ] && [ ! -L "$home/.config/gh" ] || fail_test 'gh was not converted to a real dir'
    assert_file_contains "$home/.config/gh/hosts.yml" 'hosts secret'
    assert_symlink_to "$home/.config/gh/config.yml" "$repo/gh/config.yml"
    [ -d "$home/.config/herdr" ] && [ ! -L "$home/.config/herdr" ] || fail_test 'herdr was not converted to a real dir'
    assert_file_contains "$home/.config/herdr/session.json" 'session'
    assert_file_contains "$home/.config/herdr/release-notes.json" 'release'
    assert_file_contains "$home/.config/herdr/.plugins.lock" 'lock'
    assert_file_contains "$home/.config/herdr/plugins.json" 'plugins registry'
    assert_file_contains "$home/.config/herdr/sessions/session-one.json" 'saved session'
    assert_file_contains "$home/.config/herdr/herdr-server.log" 'log'
    assert_file_contains "$home/.config/herdr/plugins/plugin" 'plugin checkout'
    assert_not_exists "$repo/herdr/stale.sock"
    assert_symlink_to "$home/.config/herdr/config.toml" "$repo/herdr/config.toml"
    assert_symlink_to "$home/.config/herdr/scripts" "$repo/herdr/scripts"
    rm -rf "$tmp"
}

test_live_herdr_socket_skips_repair() {
    local tmp repo home manifest bin out status
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/links.txt"
    bin="$tmp/bin"
    write_fake_bin "$bin"
    mkdir -p "$home/.config"
    printf 'sock\n' >"$repo/herdr/live.sock"
    ln -s "$repo/herdr" "$home/.config/herdr"
    cat >"$manifest" <<EOF
- ~/.config/herdr realdir
herdr/config.toml ~/.config/herdr/config.toml
EOF

    out="$(FAKE_LOG="$tmp/fake.log" FAKE_PGREP_STATUS=0 PATH="$bin:$PATH" run_install "$repo" "$home" "$manifest")"
    [ -L "$home/.config/herdr" ] || fail_test 'live Herdr socket repair should leave symlink in place'
    assert_file_contains "$repo/herdr/live.sock" 'sock'
    printf '%s\n' "$out" | grep -F -q 'stop Herdr and re-run' || fail_test 'live Herdr warning missing'

    set +e
    FAKE_LOG="$tmp/fake.log" FAKE_PGREP_STATUS=0 PATH="$bin:$PATH" HOME="$home" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only links --check >/dev/null
    status=$?
    set -e
    [ "$status" -eq 2 ] || fail_test "live Herdr socket --check should report drift with exit 2, got $status"
    rm -rf "$tmp"
}

test_gitconfig_adoption_preserves_local_values() {
    local tmp repo home manifest before_helpers after_helpers full_config
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/empty-links.txt"
    mkdir -p "$home"
    : >"$manifest"
    cat >"$home/.gitconfig" <<'EOF'
[user]
  name = Local User
  email = local@example.test
  signingkey = ~/.ssh/local.pub
[credential]
  helper = osxkeychain
  helper = store --file ~/.git-credentials-local
EOF
    printf '[old]\n  value = true\n' >"$home/.gitconfig.local"

    before_helpers="$(HOME="$home" git config --global --includes --get-all credential.helper)"
    run_install "$repo" "$home" "$manifest" --adopt-gitconfig >/dev/null
    assert_symlink_to "$home/.gitconfig" "$repo/gitconfig"
    assert_file_contains "$home/.gitconfig.local" 'Local User'
    assert_file_contains "$home/.gitconfig.local" 'osxkeychain'
    find "$home/.dotfiles-backup" -name .gitconfig.local -type f | grep -q . || fail_test 'existing .gitconfig.local was not backed up'
    [ "$(HOME="$home" git config --global --includes --get user.name)" = 'Local User' ] || fail_test 'effective git user.name was not preserved'
    after_helpers="$(HOME="$home" git config --global --includes --get-all credential.helper)"
    [ "$before_helpers" = "$after_helpers" ] || fail_test 'effective multi-valued credential.helper was not preserved'
    full_config="$(HOME="$home" git config --global --includes --list)"
    printf '%s\n' "$full_config" | grep -Fx -q 'user.name=Local User' || fail_test 'git config --list did not include local user.name'
    printf '%s\n' "$full_config" | grep -Fx -q 'credential.helper=osxkeychain' || fail_test 'git config --list did not include osxkeychain helper'
    printf '%s\n' "$full_config" | grep -Fx -q 'credential.helper=store --file ~/.git-credentials-local' || fail_test 'git config --list did not include second credential.helper'
    rm -rf "$tmp"
}

test_gitconfig_real_file_without_adopt_reports_drift() {
    local tmp repo home manifest status before after out
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/empty-links.txt"
    mkdir -p "$home/.config" "$home/.local/bin"
    : >"$manifest"
    printf '[user]\n  name = Keep Me\n' >"$home/.gitconfig"

    before="$(snapshot_tree "$home")"
    out="$(run_install "$repo" "$home" "$manifest")"
    after="$(snapshot_tree "$home")"
    [ "$before" = "$after" ] || fail_test 'gitconfig real file changed without --adopt-gitconfig'
    printf '%s\n' "$out" | grep -F -q 'gitconfig drift' || fail_test 'gitconfig drift warning missing'

    set +e
    HOME="$home" INSTALL_MAC_LINKS_FILE="$manifest" "$repo/install-mac" --only links --check >/dev/null
    status=$?
    set -e
    [ "$status" -eq 2 ] || fail_test "gitconfig drift --check should exit 2, got $status"
    rm -rf "$tmp"
}

write_fake_bin() {
    local bin="$1"
    mkdir -p "$bin"
    cat >"$bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "$1" = plugin ] && [ "$2" = list ]; then
    if [ "${FAKE_HERDR_ALL_PLUGINS:-0}" = 1 ]; then
        cat <<'LIST'
6 plugins installed:
- herdr-floax (herdr-floax) enabled [github:Tyru5/herdr-floax@abc]
- herdr-navigator (Herdr Navigator) enabled [github:thanhdat77/herdr-navigator@abc]
- jt.command-palette (Command Palette) enabled [github:JanTvrdik/herdr-command-palette@abc]
- rmarganti.herdr-pluck (Herdr Pluck) enabled [github:rmarganti/herdr-pluck@abc]
- termscope (Termscope) enabled [github:iurysza/termscope@abc]
- vim-herdr-navigation (Vim Herdr Navigation) enabled [github:paulbkim-dev/vim-herdr-navigation@abc]
LIST
    elif [ "${FAKE_HERDR_LEGACY:-0}" = 1 ]; then
        cat <<'LIST'
2 plugins installed:
- herdr-picker-plus (Herdr Picker Plus) enabled [github:thanhdat77/herdr-navigator@old]
- vim-herdr-navigation (Vim Herdr Navigation) enabled [github:paulbkim-dev/vim-herdr-navigation@abc]
LIST
    else
        cat <<'LIST'
2 plugins installed:
- vim-herdr-navigation (Vim Herdr Navigation) enabled [github:paulbkim-dev/vim-herdr-navigation@abc]
- rmarganti.herdr-pluck (Herdr Pluck) enabled [github:rmarganti/herdr-pluck@abc]
LIST
    fi
elif [ "$1" = plugin ] && [ "$2" = install ]; then
    printf 'herdr install %s %s\n' "$3" "$4" >>"$FAKE_LOG"
elif [ "$1" = plugin ] && [ "$2" = uninstall ]; then
    printf 'herdr uninstall %s\n' "$3" >>"$FAKE_LOG"
else
    printf 'unexpected herdr args: %s\n' "$*" >&2
    exit 1
fi
EOF
    chmod +x "$bin/herdr"
    cat >"$bin/mise" <<'EOF'
#!/usr/bin/env bash
printf 'mise %s\n' "$*" >>"$FAKE_LOG"
if [ "${1:-}" = ls ] && [ "${2:-}" = --missing ]; then
    case "${FAKE_MISE_LS:-clean}" in
        fail) exit 1 ;;
        missing) printf 'node  26.10.0\n' ;;
    esac
fi
EOF
    chmod +x "$bin/mise"
    cat >"$bin/nvim" <<'EOF'
#!/usr/bin/env bash
printf 'nvim %s\n' "$*" >>"$FAKE_LOG"
EOF
    chmod +x "$bin/nvim"
    cat >"$bin/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'brew %s\n' "$*" >>"$FAKE_LOG"
if [ "${1:-}" = bundle ]; then
    [ "${HOMEBREW_NO_AUTO_UPDATE:-}" = 1 ] || { echo 'missing HOMEBREW_NO_AUTO_UPDATE' >&2; exit 9; }
    [ "${HOMEBREW_NO_INSTALL_CLEANUP:-}" = 1 ] || { echo 'missing HOMEBREW_NO_INSTALL_CLEANUP' >&2; exit 9; }
    [ "${HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK:-}" = 1 ] || { echo 'missing HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK' >&2; exit 9; }
fi
if [ "${1:-}" = bundle ] && [ "${2:-}" = check ]; then
    saw_no_upgrade=0
    for arg in "$@"; do
        [ "$arg" = --no-upgrade ] && saw_no_upgrade=1
    done
    [ "$saw_no_upgrade" -eq 1 ] || { echo 'brew bundle check missing --no-upgrade' >&2; exit 9; }
    [ "${FAKE_BREW_CHECK:-missing}" = satisfied ] && exit 0
    exit 1
fi
if [ "${1:-}" = bundle ] && [ "${2:-}" = install ]; then
    exit 0
fi
if [ "${1:-}" = bundle ] && [ "${2:-}" = dump ]; then
    printf 'brew "tmux"\n'
    exit 0
fi
if [ "${1:-}" = --prefix ]; then
    if [ -n "${FAKE_FISH_PREFIX:-}" ]; then
        printf '%s\n' "$FAKE_FISH_PREFIX"
    else
        printf '/opt/homebrew/opt/%s\n' "${2:-fish}"
    fi
    exit 0
fi
exit 0
EOF
    chmod +x "$bin/brew"
    cat >"$bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'git %s\n' "$*" >>"$FAKE_LOG"
if [ "${1:-}" = clone ]; then
    dest="${*: -1}"
    mkdir -p "$dest/bin" "$dest/.git"
    printf '#!/usr/bin/env bash\n' >"$dest/tpm"
    chmod +x "$dest/tpm"
    cat >"$dest/bin/install_plugins" <<'SCRIPT'
#!/usr/bin/env bash
printf 'tpm install_plugins\n' >>"$FAKE_LOG"
SCRIPT
    chmod +x "$dest/bin/install_plugins"
    exit 0
fi
printf 'unexpected git args: %s\n' "$*" >&2
exit 1
EOF
    chmod +x "$bin/git"
    cat >"$bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit "${FAKE_PGREP_STATUS:-1}"
EOF
    chmod +x "$bin/pgrep"
    cat >"$bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'Darwin\n'
EOF
    chmod +x "$bin/uname"
    cat >"$bin/xcode-select" <<'EOF'
#!/usr/bin/env bash
[ "${1:-}" = -p ] && { printf '/Library/Developer/CommandLineTools\n'; exit 0; }
exit 1
EOF
    chmod +x "$bin/xcode-select"
    cat >"$bin/sudo" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'sudo %s\n' "$*" >>"$FAKE_LOG"
cat >/dev/null
exit 0
EOF
    chmod +x "$bin/sudo"
    cat >"$bin/chsh" <<'EOF'
#!/usr/bin/env bash
printf 'chsh %s\n' "$*" >>"$FAKE_LOG"
EOF
    chmod +x "$bin/chsh"
}

test_gitconfig_linked_without_local_warns() {
    local tmp repo home manifest out
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/empty-links.txt"
    mkdir -p "$home/.config" "$home/.local/bin"
    : >"$manifest"
    ln -s "$repo/gitconfig" "$home/.gitconfig"

    out="$(run_install "$repo" "$home" "$manifest")"
    printf '%s\n' "$out" | grep -F -q '.gitconfig.local is missing' || fail_test 'linked gitconfig without .gitconfig.local did not warn'
    rm -rf "$tmp"
}

test_herdr_plugins_only_missing_and_section_selection() {
    local tmp repo home manifest bin log out
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/empty-links.txt"
    bin="$tmp/bin"
    log="$tmp/fake.log"
    mkdir -p "$home" "$repo/herdr"
    : >"$manifest"
    cp "$ROOT/herdr/plugins.txt" "$repo/herdr/plugins.txt"
    write_fake_bin "$bin"

    FAKE_LOG="$log" HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only herdr-plugins >/dev/null
    grep -F -q 'herdr install JanTvrdik/herdr-command-palette --yes' "$log" || fail_test 'missing command-palette plugin was not installed'
    grep -F -q 'herdr install Tyru5/herdr-floax --yes' "$log" || fail_test 'missing floax plugin was not installed'
    ! grep -F -q 'herdr install paulbkim-dev/vim-herdr-navigation' "$log" || fail_test 'already-installed plugin was reinstalled'

    : >"$log"
    FAKE_LOG="$log" HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only brew --apps >/dev/null
    grep -F -q 'brew bundle install' "$log" || fail_test 'brew section did not install missing bundle items'
    grep -F -q 'Brewfile.apps' "$log" || fail_test '--apps did not include mac/Brewfile.apps'

    : >"$log"
    out="$(FAKE_LOG="$log" HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only mise,nvim --skip nvim)"
    grep -F -q 'mise trust' "$log" || fail_test 'selected mise section did not run'
    ! grep -F -q 'nvim ' "$log" || fail_test 'skipped nvim section ran'
    printf '%s\n' "$out" | grep -F -q 'skipping section: nvim' || fail_test 'skip output missing for nvim'
    rm -rf "$tmp"
}

test_failed_link_command_marks_section_failed() {
    local tmp repo home manifest bin status out
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/links.txt"
    bin="$tmp/bin"
    mkdir -p "$home/.config" "$home/.local/bin" "$bin" "$repo/src"
    printf 'source\n' >"$repo/src/file"
    ln -s "$repo/gitconfig" "$home/.gitconfig"
    printf '[local]\n  value = true\n' >"$home/.gitconfig.local"
    cat >"$manifest" <<EOF
src/file ~/.config/file
EOF
    cat >"$bin/ln" <<'EOF'
#!/usr/bin/env bash
exit 7
EOF
    chmod +x "$bin/ln"

    set +e
    out="$(HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" "$repo/install-mac" --only links 2>&1)"
    status=$?
    set -e
    [ "$status" -eq 1 ] || fail_test "failed ln should make install-mac exit 1, got $status: $out"
    printf '%s\n' "$out" | grep -F -q 'failed to link ~/.config/file' || fail_test 'failed ln did not report link failure'
    ! printf '%s\n' "$out" | grep -F -q 'linked ~/.config/file' || fail_test 'failed ln was reported as a successful link'
    rm -rf "$tmp"
}

test_brewfile_mise_lint_backend_prefixed_overlap() {
    local tmp repo status output
    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    mkdir -p "$repo/mac/tests" "$repo/mise"
    cp "$ROOT/mac/tests/brewfile-mise-lint.sh" "$repo/mac/tests/brewfile-mise-lint.sh"
    chmod +x "$repo/mac/tests/brewfile-mise-lint.sh"
    cat >"$repo/mac/Brewfile" <<'EOF'
brew "tmuxinator"
brew "shellcheck"
EOF
    : >"$repo/mac/Brewfile.apps"
    cat >"$repo/mise/config.toml" <<'EOF'
[tools]
"gem:tmuxinator" = "latest"
"npm:@scope/shellcheck" = "latest"
EOF

    set +e
    output="$("$repo/mac/tests/brewfile-mise-lint.sh" 2>&1)"
    status=$?
    set -e
    [ "$status" -ne 0 ] || fail_test 'Brewfile/mise lint allowed backend-prefixed overlaps'
    printf '%s\n' "$output" | grep -F -q 'tmuxinator' || fail_test 'Brewfile/mise lint did not report gem-prefixed overlap'
    printf '%s\n' "$output" | grep -F -q 'shellcheck' || fail_test 'Brewfile/mise lint did not report scoped npm-prefixed overlap'
    rm -rf "$tmp"
}

test_brew_check_uses_no_upgrade_and_noop() {
    local tmp repo home manifest bin log out
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/empty-links.txt"
    bin="$tmp/bin"
    log="$tmp/fake.log"
    mkdir -p "$home"
    : >"$manifest"
    write_fake_bin "$bin"

    FAKE_LOG="$log" FAKE_BREW_CHECK=missing HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only brew >/dev/null
    grep -F -q 'brew bundle check --no-upgrade' "$log" || fail_test 'brew check did not use --no-upgrade before install'
    grep -F -q 'brew bundle install' "$log" || fail_test 'brew install was not run when check reported missing items'

    : >"$log"
    out="$(FAKE_LOG="$log" FAKE_BREW_CHECK=satisfied HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only brew --apps)"
    grep -F -q 'brew bundle check --no-upgrade' "$log" || fail_test 'satisfied brew check did not use --no-upgrade'
    ! grep -F -q 'brew bundle install' "$log" || fail_test 'satisfied brew bundle should be a no-op without install'
    ! printf '%s\n' "$out" | grep -q '^change installed missing Homebrew items' || fail_test "satisfied brew run reported install change: $out"
    rm -rf "$tmp"
}

test_gh_hosts_history_recovery() {
    local tmp repo home manifest git_home
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/links.txt"
    git_home="$tmp/git-home"
    mkdir -p "$home/.config" "$git_home"
    printf 'historical hosts secret\n' >"$repo/gh/hosts.yml"
    (
        cd "$repo"
        HOME="$git_home" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git init -q
        HOME="$git_home" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git config user.name 'Test User'
        HOME="$git_home" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git config user.email test@example.test
        HOME="$git_home" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git add gh/hosts.yml
        HOME="$git_home" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c commit.gpgsign=false commit -q -m 'track gh hosts'
        rm gh/hosts.yml
        HOME="$git_home" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git add -u gh/hosts.yml
        HOME="$git_home" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c commit.gpgsign=false commit -q -m 'remove gh hosts'
    )
    ln -s "$repo/gh" "$home/.config/gh"
    cat >"$manifest" <<EOF
- ~/.config/gh realdir
gh/config.yml ~/.config/gh/config.yml
EOF

    run_install "$repo" "$home" "$manifest" >/dev/null
    assert_file_contains "$home/.config/gh/hosts.yml" 'historical hosts secret'
    assert_symlink_to "$home/.config/gh/config.yml" "$repo/gh/config.yml"
    rm -rf "$tmp"
}

test_tmux_fish_agent_stack_and_drift() {
    local tmp repo home manifest bin log fish_prefix status
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/empty-links.txt"
    bin="$tmp/bin"
    log="$tmp/fake.log"
    fish_prefix="$tmp/fish-prefix"
    mkdir -p "$home" "$fish_prefix/bin"
    : >"$manifest"
    printf '#!/usr/bin/env bash\n' >"$fish_prefix/bin/fish"
    chmod +x "$fish_prefix/bin/fish"
    write_fake_bin "$bin"

    FAKE_LOG="$log" HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only tmux >/dev/null
    grep -F -q "git clone --depth 1 https://github.com/tmux-plugins/tpm $home/.config/tmux/plugins/tpm" "$log" || fail_test 'tmux did not clone TPM into ~/.config/tmux/plugins/tpm'
    grep -F -q 'tpm install_plugins' "$log" || fail_test 'TPM install_plugins did not run'
    assert_symlink_to "$home/.tmux/plugins/tpm" "$home/.config/tmux/plugins/tpm"

    rm "$home/.tmux/plugins/tpm"
    ln -s "$home/.config/tmux/plugins/missing-tpm" "$home/.tmux/plugins/tpm"
    : >"$log"
    FAKE_LOG="$log" HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only tmux >/dev/null
    assert_symlink_to "$home/.tmux/plugins/tpm" "$home/.config/tmux/plugins/tpm"

    : >"$log"
    FAKE_LOG="$log" FAKE_FISH_PREFIX="$fish_prefix" HOME="$home" PATH="$bin:$PATH" SHELL=/bin/bash INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only shell --fish-shell --yes >/dev/null
    grep -F -q 'sudo tee -a /etc/shells' "$log" || fail_test 'fish shell did not request sudo tee for /etc/shells'
    grep -F -q "chsh -s $fish_prefix/bin/fish" "$log" || fail_test 'fish shell did not run chsh'

    : >"$log"
    FAKE_LOG="$log" HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only agent-stack >/dev/null
    grep -F -q 'agent-stack' "$log" || fail_test 'agent-stack section did not run installer'

    : >"$log"
    set +e
    FAKE_LOG="$log" HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --drift >/dev/null
    status=$?
    set -e
    [ "$status" -eq 0 ] || fail_test "--drift should exit 0, got $status"
    grep -F -q 'brew bundle dump --file=- --force' "$log" || fail_test '--drift did not inspect brew bundle dump'
    rm -rf "$tmp"
}

test_usage_errors_and_clean_full_check() {
    local tmp repo home manifest bin log status tpm
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/empty-links.txt"
    bin="$tmp/bin"
    log="$tmp/fake.log"
    tpm="$home/.config/tmux/plugins/tpm"
    mkdir -p "$home/.config" "$home/.local/bin" "$tpm/bin" "$tpm/.git" "$home/.tmux/plugins"
    printf '#!/usr/bin/env bash\n' >"$tpm/tpm"
    chmod +x "$tpm/tpm"
    : >"$manifest"
    ln -s "$repo/gitconfig" "$home/.gitconfig"
    ln -s "$tpm" "$home/.tmux/plugins/tpm"
    printf '#!/usr/bin/env bash\nexit 0\n' >"$tpm/bin/install_plugins"
    chmod +x "$tpm/bin/install_plugins"
    cp "$ROOT/herdr/plugins.txt" "$repo/herdr/plugins.txt"
    write_fake_bin "$bin"

    for args in '--bogus' '--only nope' '--dry-run --check' '--only=' '--skip='; do
        set +e
        # shellcheck disable=SC2086 # intentional test of shell-style argument splitting
        HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" "$repo/install-mac" $args >/dev/null 2>&1
        status=$?
        set -e
        [ "$status" -eq 64 ] || fail_test "usage error '$args' should exit 64, got $status"
    done
    for flag in --only --skip; do
        set +e
        HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" "$repo/install-mac" "$flag" '' >/dev/null 2>&1
        status=$?
        set -e
        [ "$status" -eq 64 ] || fail_test "empty $flag value should exit 64, got $status"
    done

    set +e
    FAKE_LOG="$log" FAKE_BREW_CHECK=satisfied FAKE_HERDR_ALL_PLUGINS=1 HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --check >/dev/null
    status=$?
    set -e
    [ "$status" -eq 0 ] || fail_test "clean full --check should exit 0, got $status"
    rm -rf "$tmp"
}

test_check_exit_precedence_and_mise_probe() {
    local tmp repo home manifest bin log status
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/links.txt"
    bin="$tmp/bin"
    log="$tmp/fake.log"
    mkdir -p "$home/.config" "$home/.local/bin" "$repo/src"
    ln -s "$repo/gitconfig" "$home/.gitconfig"
    printf '[local]\n  value = true\n' >"$home/.gitconfig.local"
    printf 'drift\n' >"$repo/src/drift"
    write_fake_bin "$bin"

    # Drift (a missing link) plus a failure (a missing source): failure wins.
    cat >"$manifest" <<EOF
src/drift ~/.config/drift
src/does-not-exist ~/.config/broken
EOF
    set +e
    HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" "$repo/install-mac" --only links --check >/dev/null 2>&1
    status=$?
    set -e
    [ "$status" -eq 1 ] || fail_test "failure plus drift under --check should exit 1, got $status"

    : >"$manifest"
    for mode_status in clean:0 missing:2 fail:1; do
        set +e
        FAKE_LOG="$log" FAKE_MISE_LS="${mode_status%%:*}" HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
            "$repo/install-mac" --only mise --check >/dev/null 2>&1
        status=$?
        set -e
        [ "$status" -eq "${mode_status##*:}" ] ||
            fail_test "mise probe '${mode_status%%:*}' under --check should exit ${mode_status##*:}, got $status"
    done
    rm -rf "$tmp"
}

test_legacy_herdr_plugin_and_invalid_tpm() {
    local tmp repo home manifest bin log out status tpm
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/empty-links.txt"
    bin="$tmp/bin"
    log="$tmp/fake.log"
    tpm="$home/.config/tmux/plugins/tpm"
    mkdir -p "$home" "$repo/herdr"
    : >"$manifest"
    cp "$ROOT/herdr/plugins.txt" "$repo/herdr/plugins.txt"
    write_fake_bin "$bin"

    # The legacy plugin is reported, never uninstalled, and blocks only herdr-navigator.
    out="$(FAKE_LOG="$log" FAKE_HERDR_LEGACY=1 HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only herdr-plugins 2>&1)"
    ! grep -F -q 'herdr uninstall' "$log" || fail_test 'install-mac uninstalled a Herdr plugin'
    printf '%s\n' "$out" | grep -F -q 'herdr plugin uninstall herdr-picker-plus' || fail_test 'legacy plugin warning missing'
    ! grep -F -q 'herdr install thanhdat77/herdr-navigator' "$log" || fail_test 'herdr-navigator installed while legacy plugin present'
    grep -F -q 'herdr install JanTvrdik/herdr-command-palette --yes' "$log" || fail_test 'other plugins were blocked by the legacy plugin'
    set +e
    FAKE_LOG="$log" FAKE_HERDR_LEGACY=1 HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only herdr-plugins --check >/dev/null 2>&1
    status=$?
    set -e
    [ "$status" -eq 2 ] || fail_test "legacy Herdr plugin under --check should exit 2, got $status"

    # An empty or interrupted TPM directory is drift, and a real run backs it up and re-clones.
    mkdir -p "$tpm"
    printf 'partial\n' >"$tpm/README.md"
    set +e
    FAKE_LOG="$log" HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only tmux --check >/dev/null 2>&1
    status=$?
    set -e
    [ "$status" -eq 2 ] || fail_test "incomplete TPM under --check should exit 2, got $status"
    : >"$log"
    FAKE_LOG="$log" HOME="$home" PATH="$bin:$PATH" INSTALL_MAC_LINKS_FILE="$manifest" \
        "$repo/install-mac" --only tmux >/dev/null 2>&1
    grep -F -q "git clone --depth 1 https://github.com/tmux-plugins/tpm $tpm" "$log" || fail_test 'incomplete TPM was not re-cloned'
    [ -x "$tpm/tpm" ] && [ -d "$tpm/.git" ] || fail_test 'TPM is still incomplete after repair'
    [ -n "$(find "$home/.dotfiles-backup" -path '*tpm/README.md')" ] || fail_test 'incomplete TPM was not backed up'
    rm -rf "$tmp"
}

test_gitconfig_wrong_links_and_external_dir_links() {
    local tmp repo home manifest external
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/empty-links.txt"
    external="$tmp/external-bin"
    mkdir -p "$home/.config" "$external"
    : >"$manifest"
    printf '[local]\n  value = true\n' >"$home/.gitconfig.local"
    printf 'mine\n' >"$external/tool"

    # ~/.local/bin as a link to a directory outside the repo is kept as-is.
    mkdir -p "$home/.local"
    ln -s "$external" "$home/.local/bin"

    # A wrong ~/.gitconfig link is backed up and relinked.
    printf 'other\n' >"$tmp/other-gitconfig"
    ln -s "$tmp/other-gitconfig" "$home/.gitconfig"
    run_install "$repo" "$home" "$manifest" >/dev/null
    assert_symlink_to "$home/.gitconfig" "$repo/gitconfig"
    [ -n "$(find "$home/.dotfiles-backup" -name .gitconfig -type l)" ] || fail_test 'wrong gitconfig link was not backed up'
    assert_symlink_to "$home/.local/bin" "$external"
    assert_file_contains "$external/tool" 'mine'

    # A dangling ~/.gitconfig link is repaired too.
    rm "$home/.gitconfig"
    ln -s "$tmp/missing-gitconfig" "$home/.gitconfig"
    run_install "$repo" "$home" "$manifest" >/dev/null
    assert_symlink_to "$home/.gitconfig" "$repo/gitconfig"
    rm -rf "$tmp"
}

test_real_home_guard() {
    local before="$1" after="$2"
    [ -n "$ORIGINAL_HOME" ] || return 0
    [ "$before" = "$after" ] || fail_test 'real HOME guard detected changes to relevant real paths'
}

HARNESS_HOME=""
cleanup_harness_home() {
    # Only ever remove the temporary directory this harness created.
    case "$HARNESS_HOME" in
        "${TMPDIR:-/tmp}"/*|/tmp/*|/var/folders/*) rm -rf -- "$HARNESS_HOME" ;;
    esac
}

main() {
    local real_home_before real_home_after
    real_home_before="$(snapshot_real_home)"
    HARNESS_HOME="$(mktemp -d)"
    [ -n "$HARNESS_HOME" ] && [ -d "$HARNESS_HOME" ] || { echo "mktemp failed" >&2; exit 1; }
    export HOME="$HARNESS_HOME"
    trap cleanup_harness_home EXIT
    test_links_manifest_sources_exist
    test_link_states
    test_ghostty_cleanup_negative_cases
    test_dry_run_and_check_are_read_only
    test_gh_and_herdr_symlink_repairs
    test_live_herdr_socket_skips_repair
    test_gitconfig_adoption_preserves_local_values
    test_gitconfig_real_file_without_adopt_reports_drift
    test_gitconfig_linked_without_local_warns
    test_herdr_plugins_only_missing_and_section_selection
    test_failed_link_command_marks_section_failed
    test_brewfile_mise_lint_backend_prefixed_overlap
    test_brew_check_uses_no_upgrade_and_noop
    test_gh_hosts_history_recovery
    test_tmux_fish_agent_stack_and_drift
    test_usage_errors_and_clean_full_check
    test_check_exit_precedence_and_mise_probe
    test_legacy_herdr_plugin_and_invalid_tpm
    test_gitconfig_wrong_links_and_external_dir_links
    real_home_after="$(snapshot_real_home)"
    test_real_home_guard "$real_home_before" "$real_home_after"
    printf 'ok install-mac tests passed\n'
}

main "$@"
