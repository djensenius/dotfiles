#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$DIR/../install.sh"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/install-git-version.XXXXXX")"
cleanup() {
  rm -rf -- "$tmp"
}
trap cleanup EXIT

mkdir -p "$tmp/bin"
cat > "$tmp/bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "${FAKE_GIT_VERSION_OUTPUT:?}"
EOF
chmod 755 "$tmp/bin/git"

check_version() {
  local output="$1"
  env \
    PATH="$tmp/bin:$PATH" \
    FAKE_GIT_VERSION_OUTPUT="$output" \
    bash -c "
      source \"\$1\"
      require_git_version
      printf 'accepted:%s\\n' \"\$GIT_VERSION\"
    " bash "$INSTALLER"
}

expect_accept() {
  local output="$1" expected="$2" result
  result="$(check_version "$output")"
  [ "$result" = "accepted:$expected" ] || {
    printf 'Expected %s to be accepted as %s, got: %s\n' "$output" "$expected" "$result" >&2
    exit 1
  }
}

expect_reject() {
  local output="$1" expected_message="$2" result status
  set +e
  result="$(check_version "$output" 2>&1)"
  status=$?
  set -e
  [ "$status" -ne 0 ] || {
    printf 'Expected rejection for: %s\n' "$output" >&2
    exit 1
  }
  case "$result" in
    *"$expected_message"*) ;;
    *)
      printf 'Expected rejection containing %s, got: %s\n' "$expected_message" "$result" >&2
      exit 1
      ;;
  esac
}

expect_reject "git version 2.44.99" "Git >= 2.45.0 is required"
expect_accept "git version 2.45.0" "2.45.0"
expect_accept "git version 2.45.3.windows.1" "2.45.3"
expect_accept "git version 2.55.0 (Apple Git-155)" "2.55.0"
expect_reject "git version not-a-version" "could not parse git --version output"
expect_reject "git version 2.45.0 unexpected suffix" "could not parse git --version output"

cat > "$tmp/bin/mise" <<EOF
#!/usr/bin/env bash
set -euo pipefail
: > "$tmp/mise-called"
EOF
chmod 755 "$tmp/bin/mise"

set +e
env \
  PATH="$tmp/bin:$PATH" \
  FAKE_GIT_VERSION_OUTPUT="git version 2.44.99" \
  PI_CODING_AGENT_DIR="$tmp/pi-agent" \
  "$INSTALLER" >/dev/null 2>&1
installer_status=$?
set -e
[ "$installer_status" -ne 0 ] || {
  printf 'Installer unexpectedly accepted Git 2.44.99\n' >&2
  exit 1
}
[ ! -e "$tmp/mise-called" ] && [ ! -e "$tmp/pi-agent/extensions/reviewer-git.ts" ] || {
  printf 'Installer performed work before rejecting old Git\n' >&2
  exit 1
}

printf 'installer Git version tests passed\n'
