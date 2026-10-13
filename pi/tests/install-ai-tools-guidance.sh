#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/pi/install.sh"

if [ "$(id -u)" -eq 0 ]; then
    printf 'install-pi ai-tools guidance test skipped: must not run as root\n'
    exit 0
fi
unset INSTALL_PI_LOG

tmp="$(mktemp -d "${TMPDIR:-/tmp}/install-pi-ai-tools.XXXXXX")"
cleanup() {
    rm -rf -- "$tmp"
}
trap cleanup EXIT

fail() {
    printf 'install-pi ai-tools guidance test failed: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local needle="$1" file="$2"
    grep -Fq -- "$needle" "$file" || fail "expected '$needle' in $file"
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
    shift 2
    HOME="$home" \
    PATH="$tmp/mock-bin:/usr/bin:/bin:/usr/sbin:/sbin" \
        bash "$INSTALLER" \
            --skip-apt \
            --skip-mise \
            --skip-links \
            --skip-tmux \
            --skip-nvim \
            --skip-herdr \
            --yes \
            "$@" \
            >"$output" 2>&1
}

write_uname_mock "$tmp/mock-bin"

plain_home="$tmp/plain/home"
plain_output="$tmp/plain.out"
mkdir -p "$plain_home"
run_installer "$plain_home" "$plain_output"
assert_contains 'Run ./install-pi --ai-tools to install the full AI/coding-agent tooling stack (Pi, Herdr, subagents, memory, browser).' "$plain_output"

ai_home="$tmp/ai/home"
ai_output="$tmp/ai.out"
mkdir -p "$ai_home"
run_installer "$ai_home" "$ai_output" --ai-tools --dry-run
assert_contains "[dry-run] $REPO_ROOT/ai-tools/install.sh" "$ai_output"
assert_contains 'AI/coding-agent tooling was requested with ./install-pi --ai-tools; re-run it after related updates.' "$ai_output"

printf 'install-pi ai-tools guidance tests passed\n'
