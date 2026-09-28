#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/pi/install.sh"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/install-pi-herdr-fish.XXXXXX")"
cleanup() {
    rm -rf -- "$tmp"
}
trap cleanup EXIT

fail() {
    printf 'install-pi herdr-fish cleanup test failed: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local needle="$1" file="$2"
    grep -Fq -- "$needle" "$file" ||
        fail "expected '$needle' in $file"
}

assert_not_contains() {
    local needle="$1" file="$2"
    if grep -Fq -- "$needle" "$file"; then
        fail "did not expect '$needle' in $file"
    fi
}

write_uname_mock() {
    local destination="$1"
    mkdir -p "$destination"
    cat >"$destination/uname" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    -s) printf 'Linux\n' ;;
    -m) printf 'aarch64\n' ;;
    *) printf 'Linux\n' ;;
esac
EOF
    chmod 755 "$destination/uname"
}

run_installer() {
    local home="$1" output="$2"
    HOME="$home" \
    PATH="$tmp/mock-bin:/usr/bin:/bin:/usr/sbin:/sbin" \
        bash "$INSTALLER" \
            --skip-apt \
            --skip-mise \
            --skip-tmux \
            --skip-nvim \
            --skip-herdr \
            --yes \
            >"$output" 2>&1
}

run_removes_repo_owned_link() {
    local home="$tmp/removes/home" output="$tmp/removes.out"
    mkdir -p "$home/.local/bin"
    ln -s "$REPO_ROOT/herdr/scripts/herdr-fish.sh" "$home/.local/bin/herdr-fish"

    run_installer "$home" "$output"

    [ ! -e "$home/.local/bin/herdr-fish" ] && [ ! -L "$home/.local/bin/herdr-fish" ] ||
        fail "repo-owned legacy herdr-fish symlink was not removed"
    assert_contains "Removed legacy Herdr fish wrapper link: ~/.local/bin/herdr-fish" "$output"
}

run_preserves_user_file() {
    local home="$tmp/preserves-file/home" output="$tmp/preserves-file.out"
    mkdir -p "$home/.local/bin"
    printf '#!/bin/sh\n' >"$home/.local/bin/herdr-fish"

    run_installer "$home" "$output"

    [ -f "$home/.local/bin/herdr-fish" ] ||
        fail "user-owned herdr-fish file was removed"
    assert_not_contains "Removed legacy Herdr fish wrapper link" "$output"
}

run_preserves_other_symlink() {
    local home="$tmp/preserves-symlink/home" output="$tmp/preserves-symlink.out"
    local other_target="$tmp/other-repo/herdr/scripts/herdr-fish.sh"
    mkdir -p "$home/.local/bin" "$(dirname "$other_target")"
    printf '#!/bin/sh\n' >"$other_target"
    ln -s "$other_target" "$home/.local/bin/herdr-fish"

    run_installer "$home" "$output"

    [ -L "$home/.local/bin/herdr-fish" ] ||
        fail "non-repo herdr-fish symlink was removed"
    [ "$(readlink "$home/.local/bin/herdr-fish")" = "$other_target" ] ||
        fail "non-repo herdr-fish symlink target changed"
    assert_not_contains "Removed legacy Herdr fish wrapper link" "$output"
}

write_uname_mock "$tmp/mock-bin"
run_removes_repo_owned_link
run_preserves_user_file
run_preserves_other_symlink
