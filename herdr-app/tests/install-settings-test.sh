#!/usr/bin/env bash
# Exercise production installer paths using only disposable repos and homes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fail() { printf 'not ok %s\n' "$*" >&2; exit 1; }
# The real Pi entry point resets HOME to the account database when run as root.
[ "$(id -u)" -ne 0 ] || fail 'Herdr App settings tests must not run as root'
unset HERDR_APP_HOME XDG_CONFIG_HOME INSTALL_PI_LOG SUDO_USER

tmp="$(mktemp -d "${TMPDIR:-/tmp}/herdr-app-settings.XXXXXX")"
tmp="$(cd -P "$tmp" && pwd)"
trap 'rm -rf -- "$tmp"' EXIT
TEST_REPO="$tmp/repo"
mkdir -p "$TEST_REPO/mac" "$TEST_REPO/linux" "$TEST_REPO/pi" "$TEST_REPO/scripts/lib" "$TEST_REPO/herdr-app" \
    "$TEST_REPO/fish" "$TEST_REPO/herdr/scripts" "$tmp/bin" "$tmp/elsewhere"
cp "$ROOT/install.sh" "$TEST_REPO/install.sh"
cp "$ROOT/install-mac" "$TEST_REPO/install-mac"
cp "$ROOT/mac/install.sh" "$TEST_REPO/mac/install.sh"
cp -R "$ROOT/mac/lib" "$TEST_REPO/mac/lib"
cp "$ROOT/linux/install.sh" "$TEST_REPO/linux/install.sh"
cp "$ROOT/pi/install.sh" "$TEST_REPO/pi/install.sh"
cp "$ROOT/scripts/lib/herdr-app-settings.sh" "$TEST_REPO/scripts/lib/herdr-app-settings.sh"
cp "$ROOT/herdr-app/settings.json" "$TEST_REPO/herdr-app/settings.json"
cp "$ROOT/herdr/config.toml" "$TEST_REPO/herdr/config.toml"
cp "$ROOT/gitconfig" "$TEST_REPO/gitconfig"
cp "$ROOT/gitconfig-github" "$tmp/elsewhere/gitconfig-github"
: >"$tmp/links.txt"
printf 'ID=debian\nPRETTY_NAME="Debian fixture"\n' >"$tmp/os-release"
cat >"$tmp/bin/uname" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
    -m) printf 'aarch64\n' ;;
    *) printf 'Linux\n' ;;
esac
EOF
cat >"$tmp/bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'Unexpected sudo in isolated link tests\n' >&2
exit 1
EOF
cat >"$tmp/bin/date" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
    +%Y%m%d-%H%M%S) printf '20000101-000000\n' ;;
    +%s) printf '946684800\n' ;;
    *) exec /bin/date "$@" ;;
esac
EOF
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin"
passed=0

# Load only source-safe Codespaces definitions with a disposable HOME.
# Timing callbacks are public test substitutes for the bootstrap's log setup.
mkdir -p "$tmp/source-home"
# shellcheck source=install.sh disable=SC1091
HOME="$tmp/source-home" source "$TEST_REPO/install.sh"
start_operation() { printf '0\n'; }
log_with_timing() { :; }

snapshot_tree() {
    (
        cd "$1"
        find . -mindepth 1 -print | sort | while IFS= read -r path; do
            if [ -L "$path" ]; then
                printf 'L %s %s\n' "$path" "$(readlink "$path")"
            elif [ -f "$path" ]; then
                printf 'F %s %s\n' "$path" "$(cksum <"$path")"
            elif [ -d "$path" ]; then
                printf 'D %s\n' "$path"
            else
                printf 'other %s\n' "$path"
            fi
        done
    )
}

run_installer() {
    local platform="$1" home="$2"
    shift 2
    (
        export HOME="$home" USER=fixture
        export INSTALL_MAC_LINKS_FILE="$tmp/links.txt" INSTALL_LINUX_OS_RELEASE="$tmp/os-release"
        # The desktop source must come from the installer, not the caller's cwd.
        cd "$tmp/elsewhere"
        case "$platform" in
            mac) bash "$TEST_REPO/mac/install.sh" --only links "$@" ;;
            linux) bash "$TEST_REPO/linux/install.sh" --skip-packages --skip-mise --yes "$@" ;;
            pi)
                bash "$TEST_REPO/pi/install.sh" --skip-apt --skip-mise --skip-tmux \
                    --skip-nvim --skip-herdr --yes "$@"
                ;;
            codespaces)
                link_files
                ;;
        esac
    )
}

replace_settings() {
    local platform="$1" home="$2"
    shift 2
    if [ "$platform" = linux ]; then
        run_installer "$platform" "$home" --force "$@"
    else
        run_installer "$platform" "$home" "$@"
    fi
}

assert_link() {
    local dir="$1"
    [ -d "$dir" ] && [ ! -L "$dir" ] || fail "not a real desktop directory: $dir"
    [ -L "$dir/settings.json" ] || fail "settings are not linked: $dir"
    [ "$(readlink "$dir/settings.json")" = "$TEST_REPO/herdr-app/settings.json" ] ||
        fail 'desktop settings do not target the installer repository'
}

seed_owned() {
    local dir="$1"
    mkdir -p "$dir/layouts/main" "$dir/mods/local" "$dir/runtime"
    printf 'custom keys\n' >"$dir/keys.json"
    printf 'generated instructions\n' >"$dir/AGENTS.md"
    printf 'generated types\n' >"$dir/settings.d.ts"
    printf 'layout font override\n' >"$dir/layouts/main/config.json"
    printf 'shipped mod\n' >"$dir/mods/local/index.js"
    printf 'runtime state\000bytes\n' >"$dir/runtime/state.db"
}

owned_snapshot() {
    local dir="$1" file
    for file in keys.json AGENTS.md settings.d.ts; do
        printf '%s %s\n' "$file" "$(cksum <"$dir/$file")"
        [ ! -L "$dir/$file" ] || fail "app-owned file became a link: $file"
    done
    snapshot_tree "$dir/layouts"
    snapshot_tree "$dir/mods"
    snapshot_tree "$dir/runtime"
}

backup_paths() {
    local platform="$1" home="$2" dir="$3"
    case "$platform" in
        mac|pi)
            [ -d "$home/.dotfiles-backup" ] || return 0
            find "$home/.dotfiles-backup" -name 'settings.json*' -print | sort
            ;;
        *) find "$dir" -maxdepth 1 -name 'settings.json.backup*' -print | sort ;;
    esac
}

assert_saved() {
    local platform="$1" home="$2" dir="$3" original="$4" path found=false
    while IFS= read -r path; do
        [ -f "$path" ] || continue
        if cmp -s "$original" "$path"; then
            [ ! -L "$path" ] || fail 'settings bytes backup must not depend on the old link'
            found=true
        fi
    done < <(backup_paths "$platform" "$home" "$dir")
    "$found" || fail "$platform did not back up the original settings bytes"
}

test_initial_and_preserved() {
    local platform="$1" case_dir="$tmp/$1-preserved" home dir before backups output
    home="$case_dir/home"
    dir="$home/.config/herdr-app"
    mkdir -p "$home"
    output="$(run_installer "$platform" "$home")"
    assert_link "$dir"
    [ "$(find "$dir" -mindepth 1 | wc -l | tr -d ' ')" -eq 1 ] ||
        fail "$platform created desktop files besides settings.json"

    seed_owned "$dir"
    before="$(owned_snapshot "$dir")"
    rm "$dir/settings.json"
    printf '{ "zoom": 1.25, "custom": "keep formatting" }\n\n' >"$case_dir/original"
    cp "$case_dir/original" "$dir/settings.json"
    if [ "$platform" = linux ]; then
        output="$(run_installer "$platform" "$home")"
        cmp -s "$case_dir/original" "$dir/settings.json" || fail 'Linux changed settings without --force'
        [ -z "$(backup_paths "$platform" "$home" "$dir")" ] || fail 'Linux backed up a skipped file'
    fi
    output="$(replace_settings "$platform" "$home")"
    assert_link "$dir"
    assert_saved "$platform" "$home" "$dir" "$case_dir/original"
    [ "$before" = "$(owned_snapshot "$dir")" ] || fail "$platform changed app-owned files"
    before="$(snapshot_tree "$dir")"
    backups="$(backup_paths "$platform" "$home" "$dir")"
    output="$(replace_settings "$platform" "$home")"
    [ "$before" = "$(snapshot_tree "$dir")" ] || fail "$platform desktop rerun was not idempotent"
    [ "$backups" = "$(backup_paths "$platform" "$home" "$dir")" ] || fail "$platform rerun made extra backups"
    if [ "$platform" = mac ]; then
        output="$(run_installer mac "$home" --check)"
    fi
}

test_read_only_and_skip() {
    local platform="$1" home="$tmp/$1-modes/home" dir before output status
    dir="$home/.config/herdr-app"
    seed_owned "$dir"
    printf 'personal settings\n' >"$dir/settings.json"
    before="$(snapshot_tree "$home")"
    if [ "$platform" = codespaces ]; then
        output="$(HOME="$home" bash -c 'source "$1/install.sh"' _ "$TEST_REPO")"
        [ -z "$output" ] || fail 'sourcing Codespaces bootstrap produced output'
        [ "$before" = "$(snapshot_tree "$home")" ] || fail 'sourcing Codespaces bootstrap wrote files'
        return
    fi
    if [ "$platform" = pi ]; then
        output="$(run_installer pi "$home" --dry-run --force)"
    else
        output="$(replace_settings "$platform" "$home" --dry-run)"
    fi
    [ "$before" = "$(snapshot_tree "$home")" ] || fail "$platform dry-run wrote files"
    if [ "$platform" = mac ]; then
        status=0
        output="$(run_installer mac "$home" --check)" || status=$?
        [ "$status" -eq 2 ] || fail "Mac drift check returned $status, not 2"
        [ "$before" = "$(snapshot_tree "$home")" ] || fail 'Mac --check wrote files'
        output="$(run_installer mac "$home" --skip links)"
        [ "$before" = "$(snapshot_tree "$home")" ] || fail 'Mac skipped links wrote files'
    else
        before="$(snapshot_tree "$dir")"
        output="$(run_installer "$platform" "$home" --skip-links --force)"
        [ "$before" = "$(snapshot_tree "$dir")" ] || fail "$platform --skip-links changed desktop state"
        [ -z "$(backup_paths "$platform" "$home" "$dir")" ] || fail "$platform --skip-links made a backup"
    fi
}

test_replacement_edges() {
    local platform="$1" case_dir="$tmp/$1-edges" home dir before output backups path found
    home="$case_dir/home"
    dir="$home/.config/herdr-app"
    seed_owned "$dir"
    printf 'relative linked personal settings\n\n' >"$dir/personal.json"
    cp "$dir/personal.json" "$case_dir/original"
    ln -s personal.json "$dir/settings.json"
    output="$(replace_settings "$platform" "$home")"
    assert_link "$dir"
    assert_saved "$platform" "$home" "$dir" "$case_dir/original"
    cmp -s "$case_dir/original" "$dir/personal.json" || fail "$platform changed the old settings referent"

    # Freeze the clock so Pi and Mac backup collision handling is exercised.
    rm "$dir/settings.json"
    printf 'second settings bytes\n' >"$case_dir/second"
    cp "$case_dir/second" "$dir/settings.json"
    output="$(replace_settings "$platform" "$home")"
    assert_saved "$platform" "$home" "$dir" "$case_dir/original"
    assert_saved "$platform" "$home" "$dir" "$case_dir/second"
    if [ "$platform" = pi ]; then
        rm "$dir/settings.json"
        printf 'settings that must survive --force\n' >"$case_dir/forced"
        cp "$case_dir/forced" "$dir/settings.json"
        rm "$home/.gitconfig"
        printf 'unrelated forced config\n' >"$home/.gitconfig"
        output="$(run_installer pi "$home" --force)"
        assert_saved pi "$home" "$dir" "$case_dir/forced"
        [ -L "$home/.gitconfig" ] || fail 'Pi --force no longer replaces unrelated configs'
        [ -z "$(find "$home/.dotfiles-backup" -name .gitconfig -print)" ] ||
            fail 'Pi --force unexpectedly changed unrelated backup behavior'
    fi

    rm "$dir/settings.json"
    ln -s nonexistent.json "$dir/settings.json"
    output="$(replace_settings "$platform" "$home")"
    assert_link "$dir"
    found=false
    while IFS= read -r path; do
        if [ -L "$path" ] && [ "$(readlink "$path")" = nonexistent.json ]; then
            found=true
        fi
    done < <(backup_paths "$platform" "$home" "$dir")
    "$found" || fail "$platform discarded a dangling settings link"

    rm "$dir/settings.json"
    mkdir "$dir/settings.json"
    printf 'misplaced settings-directory data\n' >"$dir/settings.json/sentinel"
    output="$(replace_settings "$platform" "$home")"
    assert_link "$dir"
    found=false
    while IFS= read -r path; do
        if [ -f "$path/sentinel" ]; then
            found=true
        fi
    done < <(backup_paths "$platform" "$home" "$dir")
    "$found" || fail "$platform discarded an existing settings directory"

    # A relative, multi-hop link to the right file is already correct.
    rm "$dir/settings.json"
    ln -s "$TEST_REPO/herdr-app/settings.json" "$dir/repo-settings"
    ln -s repo-settings "$dir/settings.json"
    before="$(snapshot_tree "$dir")"
    backups="$(backup_paths "$platform" "$home" "$dir")"
    output="$(replace_settings "$platform" "$home")"
    [ "$before" = "$(snapshot_tree "$dir")" ] || fail "$platform replaced a correct relative settings link"
    [ "$backups" = "$(backup_paths "$platform" "$home" "$dir")" ] || fail "$platform backed up a correct relative link"
}

test_config_home_precedence() {
    local platform="$1" case_dir="$tmp/$1-precedence" mode home dir default_dir xdg explicit_dir other1 other2 before other_before output
    for mode in xdg-only explicit-precedence empty-herdr empty-xdg empty-both unset-both; do
        home="$case_dir/$mode/home"
        default_dir="$home/.config/herdr-app"
        xdg="$case_dir/$mode/xdg.. home"
        explicit_dir="$case_dir/$mode/explicit home"
        for dir in "$default_dir" "$xdg/herdr-app" "$explicit_dir"; do
            seed_owned "$dir"
            printf 'personal settings: %s\n\n' "$dir" >"$dir/settings.json"
        done
        case "$mode" in
            xdg-only|empty-herdr)
                dir="$xdg/herdr-app"; other1="$default_dir"; other2="$explicit_dir"
                ;;
            explicit-precedence)
                dir="$explicit_dir"; other1="$default_dir"; other2="$xdg/herdr-app"
                ;;
            *)
                dir="$default_dir"; other1="$xdg/herdr-app"; other2="$explicit_dir"
                ;;
        esac
        cp "$dir/settings.json" "$case_dir/$mode/original"
        before="$(owned_snapshot "$dir")"
        other_before="$(snapshot_tree "$other1"; snapshot_tree "$other2")"
        output="$(
            unset HERDR_APP_HOME XDG_CONFIG_HOME
            case "$mode" in
                xdg-only) export XDG_CONFIG_HOME="$xdg" ;;
                explicit-precedence) export HERDR_APP_HOME="$explicit_dir" XDG_CONFIG_HOME="$xdg" ;;
                empty-herdr) export HERDR_APP_HOME="" XDG_CONFIG_HOME="$xdg" ;;
                empty-xdg) export XDG_CONFIG_HOME="" ;;
                empty-both) export HERDR_APP_HOME="" XDG_CONFIG_HOME="" ;;
                unset-both) ;;
            esac
            replace_settings "$platform" "$home"
        )"
        [ -L "$dir/settings.json" ] || fail "$platform selected the wrong config home: $mode"
        assert_link "$dir"
        assert_saved "$platform" "$home" "$dir" "$case_dir/$mode/original"
        [ "$before" = "$(owned_snapshot "$dir")" ] || fail "$platform changed app-owned files: $mode"
        [ "$other_before" = "$(snapshot_tree "$other1"; snapshot_tree "$other2")" ] ||
            fail "$platform changed an overridden config home: $mode"
        if [ "$platform" = mac ]; then
            case "$output" in
                *"desktop Herdr App settings link: $dir/settings.json"*) ;;
                *) fail "Mac reported the wrong config home: $mode" ;;
            esac
        fi
    done
}

test_custom_and_unsafe_homes() {
    local platform="$1" case_dir="$tmp/$1-homes" home dir before output status unsafe_home override_home backups expected_error
    home="$case_dir/home"
    dir="$case_dir/custom home"
    mkdir -p "$home"
    seed_owned "$dir"
    printf 'custom home settings\n' >"$case_dir/original"
    cp "$case_dir/original" "$dir/settings.json"
    before="$(owned_snapshot "$dir")"
    output="$(HERDR_APP_HOME="$dir" replace_settings "$platform" "$home")"
    assert_link "$dir"
    assert_saved "$platform" "$home" "$dir" "$case_dir/original"
    [ "$before" = "$(owned_snapshot "$dir")" ] || fail "$platform changed custom-home app files"
    [ ! -e "$home/.config/herdr-app" ] || fail "$platform ignored HERDR_APP_HOME"

    before="$(snapshot_tree "$dir")"
    for override_home in "$dir/." "$dir/././/"; do
        output="$(HERDR_APP_HOME="$override_home" replace_settings "$platform" "$home")"
        assert_link "$dir"
        [ "$before" = "$(snapshot_tree "$dir")" ] || fail "$platform changed a real dot-suffixed config home"
    done

    # Keep personal bytes at the referent so a bypass would replace settings,
    # rather than merely report an already-correct settings link.
    rm "$dir/settings.json"
    cp "$case_dir/original" "$dir/settings.json"
    ln -s "$dir" "$home/.config/herdr-app"
    before="$(snapshot_tree "$dir")"
    backups="$(backup_paths "$platform" "$home" "$dir")"
    for unsafe_home in "$home/.config/herdr-app" "$home/.config/herdr-app/" \
        "$home/.config/herdr-app/." "$home/.config/herdr-app/./" \
        "$home/.config/herdr-app/././/" "$home/.config/herdr-app//.///./" \
        "$home/.config/herdr-app/layouts/.." "$home/.config/herdr-app/layouts/../." \
        "$home/.config/herdr-app/layouts/../mods/.."; do
        case "/$unsafe_home/" in
            */../*) expected_error='config home must not contain parent-directory (..) components' ;;
            *) expected_error='config home must be a real directory' ;;
        esac
        status=0
        output="$(HERDR_APP_HOME="$unsafe_home" replace_settings "$platform" "$home" 2>&1)" || status=$?
        [ "$status" -ne 0 ] || fail "$platform accepted a symlinked desktop config directory: ${unsafe_home#"$home"}"
        [ -L "$home/.config/herdr-app" ] || fail "$platform replaced an app-owned directory link"
        [ "$(readlink "$home/.config/herdr-app")" = "$dir" ] || fail "$platform retargeted an app-owned directory link"
        [ "$before" = "$(snapshot_tree "$dir")" ] || fail "$platform wrote through an app-owned directory link"
        [ "$backups" = "$(backup_paths "$platform" "$home" "$dir")" ] || fail "$platform backed up settings through an app-owned directory link"
        case "$output" in
            *"$expected_error"*) ;;
            *) fail "$platform did not explain unsafe desktop config home" ;;
        esac
    done
    rm "$home/.config/herdr-app"
    printf 'not a directory\n' >"$home/.config/herdr-app"
    status=0
    output="$(replace_settings "$platform" "$home" 2>&1)" || status=$?
    [ "$status" -ne 0 ] || fail "$platform accepted a non-directory desktop config home"
    [ "$(cat "$home/.config/herdr-app")" = 'not a directory' ] || fail "$platform replaced a non-directory config home"
}

test_root_home_spellings() (
    # Isolate the helper and give it a no-write runner even if dry-run regresses.
    for root_home in / // /. /./ /././/; do
        output="$(HOME="$tmp/root-home" HERDR_APP_HOME="$root_home" DRY_RUN=true bash -c '
            source "$1/scripts/lib/herdr-app-settings.sh"
            link_herdr_app_settings "$1" true false
        ' _ "$TEST_REPO")" || fail "root config home was rejected: $root_home"
        case "$output" in
            *"would link //settings.json -> "*) ;;
            *) fail "root config home was not preserved: $root_home" ;;
        esac
    done
)

for platform in mac linux pi codespaces; do
    for test in initial_and_preserved read_only_and_skip replacement_edges config_home_precedence custom_and_unsafe_homes; do
        "test_$test" "$platform"
        printf 'ok %s %s\n' "$platform" "$test"
        passed=$((passed + 1))
    done
done
test_root_home_spellings
printf 'ok root_home_spellings\n'
passed=$((passed + 1))
cmp -s "$ROOT/herdr-app/settings.json" "$TEST_REPO/herdr-app/settings.json" || fail 'installer changed tracked desktop settings'
cmp -s "$ROOT/herdr/config.toml" "$TEST_REPO/herdr/config.toml" || fail 'installer changed tracked TUI config'
printf 'Herdr App settings tests: %s passed, 0 failed\n' "$passed"
