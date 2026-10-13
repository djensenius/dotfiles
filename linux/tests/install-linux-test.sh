#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/linux/install.sh"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/install-linux.XXXXXX")"
cleanup() {
    rm -rf -- "$tmp"
}
trap cleanup EXIT

fail() {
    printf 'install-linux test failed: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local needle="$1" file="$2"
    grep -Fq -- "$needle" "$file" || fail "expected '$needle' in $file"
}

assert_not_contains() {
    local needle="$1" file="$2"
    if grep -Fq -- "$needle" "$file"; then
        fail "did not expect '$needle' in $file"
    fi
}

assert_symlink_to() {
    local link="$1" expected="$2" actual
    [ -L "$link" ] || fail "expected $link to be a symlink"
    actual="$(readlink "$link")"
    [ "$actual" = "$expected" ] || fail "expected $link -> $expected, got $actual"
}

write_common_mocks() {
    local bin="$1" log="$2"
    mkdir -p "$bin"
    cat >"$bin/uname" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    -s) printf 'Linux\n' ;;
    -m) printf 'x86_64\n' ;;
    *) printf 'Linux\n' ;;
esac
MOCK
    cat >"$bin/id" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    -u) printf '1000\n' ;;
    *) exec /usr/bin/id "$@" ;;
esac
MOCK
    cat >"$bin/sudo" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = "-n" ] && [ "${2:-}" = "true" ]; then
    exit 0
fi
exec "$@"
MOCK
    cat >"$bin/apt-get" <<MOCK
#!/usr/bin/env bash
set -euo pipefail
printf 'apt-get:%s\n' "\$*" >>"$log"
MOCK
    cat >"$bin/pacman" <<MOCK
#!/usr/bin/env bash
set -euo pipefail
printf 'pacman:%s\n' "\$*" >>"$log"
MOCK
    cat >"$bin/mise" <<MOCK
#!/usr/bin/env bash
set -euo pipefail
if [ "\${1:-}" = "--version" ]; then
    printf 'mise 2026.1.0\n'
    exit 0
fi
printf 'mise:%s\n' "\$*" >>"$log"
MOCK
    chmod 755 "$bin"/*
}

write_root_id_mock() {
    local bin="$1"
    cat >"$bin/id" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    -u) printf '0\n' ;;
    *) exec /usr/bin/id "$@" ;;
esac
MOCK
    chmod 755 "$bin/id"
}

write_os_release() {
    local file="$1" content="$2"
    printf '%s\n' "$content" >"$file"
}

run_installer() {
    local os_release="$1" log="$2" output="$3" home="$4" bin="$5"
    INSTALL_LINUX_OS_RELEASE="$os_release" \
    HOME="$home" \
    PATH="$bin:/usr/bin:/bin:/usr/sbin:/sbin" \
        "$INSTALLER" --skip-links --skip-mise --yes >"$output" 2>&1
}

run_debian_family_uses_apt() {
    local case_dir="$tmp/debian" bin="$tmp/debian/bin" log="$tmp/debian/commands.log"
    local output="$tmp/debian/output.txt" os_release="$tmp/debian/os-release" home="$tmp/debian/home"
    mkdir -p "$case_dir" "$home"
    : >"$log"
    write_common_mocks "$bin" "$log"
    write_os_release "$os_release" 'ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu Test"'

    run_installer "$os_release" "$log" "$output" "$home" "$bin"

    assert_contains 'OS: Ubuntu Test (debian family)' "$output"
    assert_contains 'apt-get:update' "$log"
    assert_contains 'apt-get:install -y --no-install-recommends ca-certificates curl wget gpg git git-lfs fish' "$log"
    assert_not_contains 'pacman:' "$log"
}

run_debian_id_like_uses_apt() {
    local case_dir="$tmp/debian-like" bin="$tmp/debian-like/bin" log="$tmp/debian-like/commands.log"
    local output="$tmp/debian-like/output.txt" os_release="$tmp/debian-like/os-release" home="$tmp/debian-like/home"
    mkdir -p "$case_dir" "$home"
    : >"$log"
    write_common_mocks "$bin" "$log"
    write_os_release "$os_release" 'ID=pop
ID_LIKE="ubuntu debian"
PRETTY_NAME="Pop Test"'

    run_installer "$os_release" "$log" "$output" "$home" "$bin"

    assert_contains 'OS: Pop Test (debian family)' "$output"
    assert_contains 'apt-get:update' "$log"
}

run_arch_family_uses_pacman() {
    local case_dir="$tmp/arch" bin="$tmp/arch/bin" log="$tmp/arch/commands.log"
    local output="$tmp/arch/output.txt" os_release="$tmp/arch/os-release" home="$tmp/arch/home"
    mkdir -p "$case_dir" "$home"
    : >"$log"
    write_common_mocks "$bin" "$log"
    write_os_release "$os_release" 'ID=arch
PRETTY_NAME="Arch Test"'

    run_installer "$os_release" "$log" "$output" "$home" "$bin"

    assert_contains 'OS: Arch Test (arch family)' "$output"
    assert_contains 'pacman:-Syu --needed --noconfirm ca-certificates curl wget gnupg git git-lfs fish' "$log"
    assert_not_contains 'apt-get:' "$log"
}

run_unsupported_is_guarded() {
    local case_dir="$tmp/unsupported" bin="$tmp/unsupported/bin" log="$tmp/unsupported/commands.log"
    local output="$tmp/unsupported/output.txt" os_release="$tmp/unsupported/os-release" home="$tmp/unsupported/home"
    local status
    mkdir -p "$case_dir" "$home"
    : >"$log"
    write_common_mocks "$bin" "$log"
    write_os_release "$os_release" 'ID=fedora
ID_LIKE="rhel fedora"
PRETTY_NAME="Fedora Test"'

    set +e
    run_installer "$os_release" "$log" "$output" "$home" "$bin"
    status=$?
    set -e

    [ "$status" -ne 0 ] || fail 'unsupported distro unexpectedly succeeded'
    assert_contains "Unsupported Linux distro family 'fedora'" "$output"
    [ ! -s "$log" ] || fail 'unsupported distro ran package-manager commands'
}

run_raspberry_pi_os_is_redirected() {
    local case_dir="$tmp/raspbian" bin="$tmp/raspbian/bin" log="$tmp/raspbian/commands.log"
    local output="$tmp/raspbian/output.txt" os_release="$tmp/raspbian/os-release" home="$tmp/raspbian/home"
    local status
    mkdir -p "$case_dir" "$home"
    : >"$log"
    write_common_mocks "$bin" "$log"
    write_os_release "$os_release" 'ID=raspbian
ID_LIKE=debian
PRETTY_NAME="Raspberry Pi OS"'

    set +e
    run_installer "$os_release" "$log" "$output" "$home" "$bin"
    status=$?
    set -e

    [ "$status" -ne 0 ] || fail 'Raspberry Pi OS unexpectedly used install-linux'
    assert_contains 'Raspberry Pi OS detected (Raspberry Pi OS); use ./install-pi' "$output"
    [ ! -s "$log" ] || fail 'Raspberry Pi OS ran package-manager commands'
}

run_os_release_is_parsed_as_text() {
    local case_dir="$tmp/text-parse" bin="$tmp/text-parse/bin" log="$tmp/text-parse/commands.log"
    local output="$tmp/text-parse/output.txt" os_release="$tmp/text-parse/os-release" home="$tmp/text-parse/home"
    local marker="$tmp/text-parse/sourced-marker"
    mkdir -p "$case_dir" "$home"
    : >"$log"
    write_common_mocks "$bin" "$log"
    write_os_release "$os_release" "ID=ubuntu
ID_LIKE=\"\$(touch '$marker') debian\"
PRETTY_NAME=\"Ubuntu Text Parse\""

    run_installer "$os_release" "$log" "$output" "$home" "$bin"

    assert_contains 'OS: Ubuntu Text Parse (debian family)' "$output"
    [ ! -e "$marker" ] || fail '/etc/os-release was sourced as shell code'
}

run_refuses_sudo_root() {
    local case_dir="$tmp/root" bin="$tmp/root/bin" log="$tmp/root/commands.log"
    local output="$tmp/root/output.txt" os_release="$tmp/root/os-release" home="$tmp/root/home"
    local status
    mkdir -p "$case_dir" "$home"
    : >"$log"
    write_common_mocks "$bin" "$log"
    write_root_id_mock "$bin"
    write_os_release "$os_release" 'ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu Test"'

    set +e
    INSTALL_LINUX_OS_RELEASE="$os_release" \
    HOME="$home" \
    SUDO_USER=alice \
    PATH="$bin:/usr/bin:/bin:/usr/sbin:/sbin" \
        "$INSTALLER" --skip-packages --skip-links --skip-mise --yes >"$output" 2>&1
    status=$?
    set -e

    [ "$status" -ne 0 ] || fail 'root/sudo invocation unexpectedly succeeded'
    assert_contains 'Do not run install-linux as root or with sudo' "$output"
    [ ! -s "$log" ] || fail 'root/sudo invocation ran commands'
}

run_links_herdr_config_as_real_dir() {
    local case_dir="$tmp/herdr" bin="$tmp/herdr/bin" log="$tmp/herdr/commands.log"
    local output="$tmp/herdr/output.txt" os_release="$tmp/herdr/os-release" home="$tmp/herdr/home"
    mkdir -p "$case_dir" "$home"
    : >"$log"
    write_common_mocks "$bin" "$log"
    write_os_release "$os_release" 'ID=debian
PRETTY_NAME="Debian Test"'

    INSTALL_LINUX_OS_RELEASE="$os_release" \
    HOME="$home" \
    PATH="$bin:/usr/bin:/bin:/usr/sbin:/sbin" \
        "$INSTALLER" --skip-packages --skip-mise --yes >"$output" 2>&1

    [ -d "$home/.config/herdr" ] && [ ! -L "$home/.config/herdr" ] || fail 'Herdr config directory is not a real directory'
    assert_symlink_to "$home/.config/herdr/config.toml" "$REPO_ROOT/herdr/config.toml"
    assert_symlink_to "$home/.config/herdr/scripts" "$REPO_ROOT/herdr/scripts"
}

run_mise_links_global_config_and_installs_from_home() {
    local case_dir="$tmp/mise" bin="$tmp/mise/bin" log="$tmp/mise/commands.log"
    local output="$tmp/mise/output.txt" os_release="$tmp/mise/os-release" home="$tmp/mise/home"
    mkdir -p "$case_dir" "$home"
    : >"$log"
    write_common_mocks "$bin" "$log"
    write_os_release "$os_release" 'ID=debian
PRETTY_NAME="Debian Test"'

    INSTALL_LINUX_OS_RELEASE="$os_release" \
    HOME="$home" \
    PATH="$bin:/usr/bin:/bin:/usr/sbin:/sbin" \
        "$INSTALLER" --skip-packages --skip-links --yes >"$output" 2>&1

    assert_symlink_to "$home/.config/mise" "$REPO_ROOT/mise"
    assert_contains "mise:trust $REPO_ROOT/mise/config.toml" "$log"
    assert_contains "mise:install -C $home" "$log"
    assert_contains 'Open a new shell and ensure ~/.local/bin plus ~/.local/share/mise/shims are on PATH.' "$output"
}

run_ai_tools_dry_run_message() {
    local case_dir="$tmp/ai-tools" bin="$tmp/ai-tools/bin" log="$tmp/ai-tools/commands.log"
    local output="$tmp/ai-tools/output.txt" os_release="$tmp/ai-tools/os-release" home="$tmp/ai-tools/home"
    mkdir -p "$case_dir" "$home"
    : >"$log"
    write_common_mocks "$bin" "$log"
    write_os_release "$os_release" 'ID=debian
PRETTY_NAME="Debian Test"'

    INSTALL_LINUX_OS_RELEASE="$os_release" \
    HOME="$home" \
    PATH="$bin:/usr/bin:/bin:/usr/sbin:/sbin" \
        "$INSTALLER" --skip-packages --skip-links --skip-mise --ai-tools --dry-run --yes >"$output" 2>&1

    assert_contains "[dry-run] $REPO_ROOT/ai-tools/install.sh" "$output"
    assert_contains 'AI/coding-agent tooling was requested with ./install-linux --ai-tools.' "$output"
    [ ! -s "$log" ] || fail 'dry-run ai-tools path ran package-manager commands'
}

run_debian_family_uses_apt
run_debian_id_like_uses_apt
run_arch_family_uses_pacman
run_unsupported_is_guarded
run_raspberry_pi_os_is_redirected
run_os_release_is_parsed_as_text
run_refuses_sudo_root
run_links_herdr_config_as_real_dir
run_mise_links_global_config_and_installs_from_home
run_ai_tools_dry_run_message

printf 'install-linux tests passed\n'
