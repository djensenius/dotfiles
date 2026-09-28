#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$DIR/../install.sh"
REPO_ROOT="$(cd "$DIR/../../.." && pwd)"
HERDR_SUBAGENTS_SOURCE="git:github.com/maxedapps/pi-subagents-herdr@3af3865a58ea4c551c3ea7b099fe8a9ea42cba83"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/install-runtime.XXXXXX")"
cleanup() {
  rm -rf -- "$tmp"
}
trap cleanup EXIT

fail() {
  printf 'installer runtime test failed: %s\n' "$*" >&2
  exit 1
}

assert_count() {
  local expected="$1" needle="$2" file="$3" actual
  actual="$(grep -Fxc -- "$needle" "$file" || true)"
  [ "$actual" = "$expected" ] ||
    fail "expected $expected occurrences of '$needle' in $file, found $actual"
}

assert_contains() {
  local needle="$1" file="$2"
  grep -Fq -- "$needle" "$file" ||
    fail "expected '$needle' in $file"
}

link_installer_utilities() {
  local destination="$1" utility source
  mkdir -p "$destination"
  for utility in basename cat chmod cmp dirname grep head install mkdir rm; do
    source="$(command -v "$utility")"
    ln -s "$source" "$destination/$utility"
  done
}

write_mise_mock() {
  local destination="$1"
  cat > "$destination" <<'EOF'
#!/bin/bash
set -euo pipefail

fail() {
  printf 'mock mise failed: %s\n' "$*" >&2
  exit 1
}

[ "${1:-}" = "-C" ] || fail "missing -C: $*"
[ "${2:-}" = "${RUNTIME_TEST_REPO_ROOT:?}" ] ||
  fail "unexpected repository: ${2:-missing}"
shift 2

action="${1:-}"
shift || true
case "$action" in
  trust)
    [ "$#" -eq 1 ] &&
      [ "$1" = "$RUNTIME_TEST_REPO_ROOT/mise/config.toml" ] ||
      fail "unexpected trust arguments: $*"
    printf 'trust:%s\n' "$1" >> "$RUNTIME_TEST_LOG"
    ;;
  install)
    [ "$#" -eq 4 ] && [ "$*" = "node npm pi herdr" ] ||
      fail "expected unified runtime install, got: $*"
    printf 'install:%s\n' "$*" >> "$RUNTIME_TEST_LOG"
    ;;
  reshim)
    [ "$#" -eq 0 ] || fail "unexpected reshim arguments: $*"
    printf 'reshim\n' >> "$RUNTIME_TEST_LOG"
    ;;
  exec)
    [ "${1:-}" = "--" ] || fail "missing exec separator: $*"
    shift
    runtime="${1:-}"
    [ -n "$runtime" ] || fail "missing exec runtime"
    shift
    case "$runtime" in
      node)
        case "${1:-}" in
          -p)
            [ "$#" -eq 2 ] && [ "$2" = "process.versions.node" ] ||
              fail "unexpected node -p arguments: $*"
            printf 'exec:node -p\n' >> "$RUNTIME_TEST_LOG"
            printf '22.19.0\n'
            ;;
          -e)
            [ "$#" -eq 3 ] && [ "$3" = "22.19.0" ] ||
              fail "unexpected node -e arguments"
            printf 'exec:node -e\n' >> "$RUNTIME_TEST_LOG"
            ;;
          *)
            fail "unexpected node arguments: $*"
            ;;
        esac
        ;;
      npx)
        if [ "$#" -eq 1 ] && [ "$1" = "--version" ]; then
          printf 'exec:npx --version\n' >> "$RUNTIME_TEST_LOG"
          printf '10.0.0\n'
        else
          [ "$*" = "-y skills add herdrdev/herdr --skill herdr --agent pi github-copilot -g -y" ] ||
            fail "unexpected npx arguments: $*"
          printf 'exec:npx skills\n' >> "$RUNTIME_TEST_LOG"
        fi
        ;;
      pi)
        subcommand="${1:-}"
        shift || true
        case "$subcommand" in
          --version)
            [ "$#" -eq 0 ] || fail "unexpected pi --version arguments: $*"
            printf 'exec:pi --version\n' >> "$RUNTIME_TEST_LOG"
            printf '0.87.1\n'
            ;;
          list)
            [ "$#" -eq 0 ] || fail "unexpected pi list arguments: $*"
            printf 'exec:pi list\n' >> "$RUNTIME_TEST_LOG"
            if [ -f "$RUNTIME_TEST_STATE/pi-installed" ]; then
              printf '  %s\n' "$RUNTIME_TEST_SOURCE"
            fi
            ;;
          install)
            [ "$#" -eq 1 ] && [ "$1" = "$RUNTIME_TEST_SOURCE" ] ||
              fail "unexpected pi install arguments: $*"
            printf 'exec:pi install:%s\n' "$1" >> "$RUNTIME_TEST_LOG"
            : > "$RUNTIME_TEST_STATE/pi-installed"
            ;;
          update)
            [ "$#" -eq 2 ] && [ "$1" = "--extension" ] &&
              [ "$2" = "$RUNTIME_TEST_SOURCE" ] ||
              fail "unexpected pi update arguments: $*"
            [ -f "$RUNTIME_TEST_STATE/pi-installed" ] ||
              fail "pi update ran before pi install"
            printf 'exec:pi update:%s\n' "$2" >> "$RUNTIME_TEST_LOG"
            ;;
          *)
            fail "unexpected pi arguments: $subcommand $*"
            ;;
        esac
        ;;
      herdr)
        if [ "$#" -eq 1 ] && [ "$1" = "--version" ]; then
          printf 'exec:herdr --version\n' >> "$RUNTIME_TEST_LOG"
          printf 'herdr 0.9.1\n'
        elif [ "$#" -eq 3 ] && [ "$1" = "integration" ] &&
          [ "$2" = "install" ] &&
          { [ "$3" = "pi" ] || [ "$3" = "copilot" ]; }; then
          printf 'exec:herdr integration %s\n' "$3" >> "$RUNTIME_TEST_LOG"
        else
          fail "unexpected herdr arguments: $*"
        fi
        ;;
      *)
        fail "unexpected runtime: $runtime"
        ;;
    esac
    ;;
  *)
    fail "unexpected action: $action"
    ;;
esac
EOF
  chmod 755 "$destination"
}

write_prerequisite_mocks() {
  local destination="$1"
  cat > "$destination/git" <<'EOF'
#!/bin/bash
set -euo pipefail
[ "$#" -eq 1 ] && [ "$1" = "--version" ] || exit 1
printf 'git version 2.55.0\n'
EOF
  cat > "$destination/curl" <<'EOF'
#!/bin/bash
exit 0
EOF
  cat > "$destination/uname" <<'EOF'
#!/bin/bash
printf 'Linux\n'
EOF
  cat > "$destination/copilot" <<'EOF'
#!/bin/bash
set -euo pipefail
: > "${RUNTIME_TEST_MARKERS:?}/system-copilot"
exit 99
EOF
  chmod 755 \
    "$destination/git" \
    "$destination/curl" \
    "$destination/uname" \
    "$destination/copilot"
}

write_system_runtime_mocks() {
  local destination="$1" runtime
  for runtime in node npx pi herdr; do
    cat > "$destination/$runtime" <<'EOF'
#!/bin/bash
set -euo pipefail
runtime="${0##*/}"
: > "${RUNTIME_TEST_MARKERS:?}/system-$runtime"
case "$runtime:${1:-}" in
  node:-p) printf '99.0.0\n' ;;
  node:-e) ;;
  npx:--version) printf '99.0.0\n' ;;
  pi:--version) printf '99.0.0\n' ;;
  herdr:--version) printf 'herdr 99.0.0\n' ;;
esac
EOF
    chmod 755 "$destination/$runtime"
  done
}

write_stale_shims() {
  local destination="$1" runtime
  mkdir -p "$destination"
  for runtime in mise node npx pi herdr; do
    cat > "$destination/$runtime" <<'EOF'
#!/bin/bash
set -euo pipefail
runtime="${0##*/}"
: > "${RUNTIME_TEST_MARKERS:?}/stale-$runtime"
exit 99
EOF
    chmod 755 "$destination/$runtime"
  done
}

run_scenario() {
  local name="$1" system_runtimes="$2"
  local root="$tmp/$name"
  local common_bin="$root/common-bin"
  local system_bin="$root/system-bin"
  local home="$root/home"
  local state="$root/state"
  local markers="$root/markers"
  local log="$root/mise.log"
  local first_output="$root/first.out"
  local second_output="$root/second.out"
  local runtime_marker

  mkdir -p "$system_bin" "$home" "$state" "$markers"
  : > "$log"
  link_installer_utilities "$common_bin"
  write_prerequisite_mocks "$system_bin"
  write_mise_mock "$system_bin/mise"
  write_stale_shims "$home/.local/share/mise/shims"
  if [ "$system_runtimes" = "yes" ]; then
    write_system_runtime_mocks "$system_bin"
  fi

  if ! env -i \
    HOME="$home" \
    PATH="$system_bin:$common_bin" \
    COPILOT_HOME="$root/copilot-home" \
    PI_CODING_AGENT_DIR="$root/pi-agent" \
    BIN_DIR="$root/local-bin" \
    RUNTIME_TEST_LOG="$log" \
    RUNTIME_TEST_MARKERS="$markers" \
    RUNTIME_TEST_REPO_ROOT="$REPO_ROOT" \
    RUNTIME_TEST_SOURCE="$HERDR_SUBAGENTS_SOURCE" \
    RUNTIME_TEST_STATE="$state" \
    /bin/bash "$INSTALLER" >"$first_output" 2>&1; then
    cat "$first_output" >&2
    fail "$name first installer run failed"
  fi

  if ! env -i \
    HOME="$home" \
    PATH="$system_bin:$common_bin" \
    COPILOT_HOME="$root/copilot-home" \
    PI_CODING_AGENT_DIR="$root/pi-agent" \
    BIN_DIR="$root/local-bin" \
    RUNTIME_TEST_LOG="$log" \
    RUNTIME_TEST_MARKERS="$markers" \
    RUNTIME_TEST_REPO_ROOT="$REPO_ROOT" \
    RUNTIME_TEST_SOURCE="$HERDR_SUBAGENTS_SOURCE" \
    RUNTIME_TEST_STATE="$state" \
    /bin/bash "$INSTALLER" >"$second_output" 2>&1; then
    cat "$second_output" >&2
    fail "$name second installer run failed"
  fi

  assert_count 2 "trust:$REPO_ROOT/mise/config.toml" "$log"
  assert_count 2 "install:node npm pi herdr" "$log"
  assert_count 2 "reshim" "$log"
  assert_count 2 "exec:node -p" "$log"
  assert_count 2 "exec:node -e" "$log"
  assert_count 2 "exec:npx --version" "$log"
  assert_count 2 "exec:npx skills" "$log"
  assert_count 2 "exec:pi --version" "$log"
  assert_count 2 "exec:pi list" "$log"
  assert_count 1 "exec:pi install:$HERDR_SUBAGENTS_SOURCE" "$log"
  assert_count 1 "exec:pi update:$HERDR_SUBAGENTS_SOURCE" "$log"
  assert_count 2 "exec:herdr --version" "$log"
  assert_count 2 "exec:herdr integration pi" "$log"
  assert_count 2 "exec:herdr integration copilot" "$log"

  for runtime_marker in "$markers"/*; do
    [ ! -e "$runtime_marker" ] ||
      fail "$name invoked unconfigured runtime marker $runtime_marker"
  done

  cmp -s \
    "$REPO_ROOT/pi/agent-stack/extensions/reviewer-git.ts" \
    "$root/pi-agent/extensions/reviewer-git.ts" ||
    fail "$name did not install the repository-owned extension"
  cmp -s \
    "$REPO_ROOT/pi/agent-stack/profiles/reviewer.md" \
    "$root/pi-agent/herdr-subagents/agents/reviewer.md" ||
    fail "$name did not install the reviewer profile"
  [ -d "$root/copilot-home" ] ||
    fail "$name did not honor COPILOT_HOME"
  assert_contains "installed reviewer-git.ts" "$first_output"
  assert_contains "reviewer-git.ts is up to date" "$second_output"
  assert_contains "reviewer.md is up to date" "$second_output"
}

run_scenario "qualifying-system-runtimes" "yes"
run_scenario "absent-system-runtimes" "no"

printf 'installer mise runtime tests passed\n'
