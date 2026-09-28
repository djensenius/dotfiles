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

setup_repo() {
    local tmp="$1" repo
    repo="$tmp/repo"
    mkdir -p "$repo"
    cp "$ROOT/install-mac" "$repo/install-mac"
    chmod +x "$repo/install-mac"
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
    mkdir -p "$repo/herdr" "$repo/gh" "$repo/scripts" "$repo/mise"
    printf 'repo gh config\n' >"$repo/gh/config.yml"
    printf 'repo herdr config\n' >"$repo/herdr/config.toml"
    mkdir -p "$repo/herdr/scripts"
    printf 'switch\n' >"$repo/scripts/switch-theme.fish"
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
    local tmp repo home manifest out backup_count
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/links.txt"
    mkdir -p "$home/.config" "$repo/src" "$repo/parent" "$repo/existing-dir"
    printf 'correct\n' >"$repo/src/correct"
    printf 'missing\n' >"$repo/src/missing"
    printf 'wrong\n' >"$repo/src/wrong"
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
    backup_count="$(find "$home/.dotfiles-backup" -type l -o -type f -o -type d | wc -l | tr -d ' ')"
    [ "$backup_count" -gt 0 ] || fail_test 'expected backups for replaced paths'

    out="$(run_install "$repo" "$home" "$manifest")"
    ! printf '%s\n' "$out" | grep -q '^change ' || fail_test "second run should be a no-op, got: $out"
    rm -rf "$tmp"
}

test_dry_run_and_check_are_read_only() {
    local tmp repo home manifest before after status
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/links.txt"
    mkdir -p "$home/.config" "$repo/src"
    printf 'source\n' >"$repo/src/file"
    printf 'old\n' >"$home/.config/file"
    printf 'src/file ~/.config/file\n' >"$manifest"

    before="$(snapshot_tree "$home")"
    run_install "$repo" "$home" "$manifest" --dry-run >/dev/null
    after="$(snapshot_tree "$home")"
    [ "$before" = "$after" ] || fail_test '--dry-run changed HOME'

    set +e
    HOME="$home" INSTALL_MAC_LINKS_FILE="$manifest" "$repo/install-mac" --only links --check >/dev/null
    status=$?
    set -e
    [ "$status" -eq 2 ] || fail_test "--check with drift should exit 2, got $status"
    after="$(snapshot_tree "$home")"
    [ "$before" = "$after" ] || fail_test '--check changed HOME'
    rm -rf "$tmp"
}

test_gh_and_herdr_symlink_repairs() {
    local tmp repo home manifest
    tmp="$(mktemp -d)"
    repo="$(setup_repo "$tmp")"
    home="$tmp/home"
    manifest="$tmp/links.txt"
    mkdir -p "$home/.config"
    printf 'hosts secret\n' >"$repo/gh/hosts.yml"
    printf 'session\n' >"$repo/herdr/session.json"
    printf 'release\n' >"$repo/herdr/release-notes.json"
    printf 'lock\n' >"$repo/herdr/.plugins.lock"
    printf 'log\n' >"$repo/herdr/herdr-server.log"
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

    run_install "$repo" "$home" "$manifest" >/dev/null
    [ -d "$home/.config/gh" ] && [ ! -L "$home/.config/gh" ] || fail_test 'gh was not converted to a real dir'
    assert_file_contains "$home/.config/gh/hosts.yml" 'hosts secret'
    assert_symlink_to "$home/.config/gh/config.yml" "$repo/gh/config.yml"
    [ -d "$home/.config/herdr" ] && [ ! -L "$home/.config/herdr" ] || fail_test 'herdr was not converted to a real dir'
    assert_file_contains "$home/.config/herdr/session.json" 'session'
    assert_file_contains "$home/.config/herdr/release-notes.json" 'release'
    assert_file_contains "$home/.config/herdr/.plugins.lock" 'lock'
    assert_file_contains "$home/.config/herdr/herdr-server.log" 'log'
    assert_not_exists "$repo/herdr/stale.sock"
    assert_symlink_to "$home/.config/herdr/config.toml" "$repo/herdr/config.toml"
    assert_symlink_to "$home/.config/herdr/scripts" "$repo/herdr/scripts"
    rm -rf "$tmp"
}

test_gitconfig_adoption_preserves_local_values() {
    local tmp repo home manifest
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
EOF
    printf '[old]\n  value = true\n' >"$home/.gitconfig.local"

    run_install "$repo" "$home" "$manifest" --adopt-gitconfig >/dev/null
    assert_symlink_to "$home/.gitconfig" "$repo/gitconfig"
    assert_file_contains "$home/.gitconfig.local" 'Local User'
    assert_file_contains "$home/.gitconfig.local" 'osxkeychain'
    find "$home/.dotfiles-backup" -name .gitconfig.local -type f | grep -q . || fail_test 'existing .gitconfig.local was not backed up'
    [ "$(HOME="$home" git config --global --includes --get user.name)" = 'Local User' ] || fail_test 'effective git user.name was not preserved'
    [ "$(HOME="$home" git config --global --includes --get credential.helper)" = 'osxkeychain' ] || fail_test 'effective credential.helper was not preserved'
    rm -rf "$tmp"
}

write_fake_bin() {
    local bin="$1"
    mkdir -p "$bin"
    cat >"$bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "$1" = plugin ] && [ "$2" = list ]; then
    printf 'paulbkim-dev/vim-herdr-navigation\nrmarganti/herdr-pluck\n'
elif [ "$1" = plugin ] && [ "$2" = install ]; then
    printf 'herdr install %s %s\n' "$3" "$4" >>"$FAKE_LOG"
else
    printf 'unexpected herdr args: %s\n' "$*" >&2
    exit 1
fi
EOF
    chmod +x "$bin/herdr"
    cat >"$bin/mise" <<'EOF'
#!/usr/bin/env bash
printf 'mise %s\n' "$*" >>"$FAKE_LOG"
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
if [ "${1:-}" = bundle ] && [ "${2:-}" = check ]; then
    exit 1
fi
if [ "${1:-}" = bundle ] && [ "${2:-}" = install ]; then
    exit 0
fi
if [ "${1:-}" = --prefix ]; then
    printf '/opt/homebrew/opt/%s\n' "${2:-fish}"
    exit 0
fi
exit 0
EOF
    chmod +x "$bin/brew"
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

test_real_home_guard() {
    local sentry
    [ -n "$ORIGINAL_HOME" ] || return 0
    sentry="$ORIGINAL_HOME/.install-mac-test-real-home-touched"
    [ ! -e "$sentry" ] || fail_test "real HOME sentry exists before test: $sentry"
    [ ! -e "$sentry" ] || fail_test 'real HOME was touched'
}

main() {
    test_link_states
    test_dry_run_and_check_are_read_only
    test_gh_and_herdr_symlink_repairs
    test_gitconfig_adoption_preserves_local_values
    test_herdr_plugins_only_missing_and_section_selection
    test_real_home_guard
    printf 'ok install-mac tests passed\n'
}

main "$@"
