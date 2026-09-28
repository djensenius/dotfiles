#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$DIR/../install.sh"
REPO_ROOT="$(cd "$DIR/../../.." && pwd)"
SUBAGENTS_SOURCE="npm:pi-subagents"
LEGACY_SOURCE="git:github.com/maxedapps/pi-subagents-herdr@3af3865a58ea4c551c3ea7b099fe8a9ea42cba83"

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

assert_not_contains() {
  local needle="$1" file="$2"
  if grep -Fq -- "$needle" "$file"; then
    fail "did not expect '$needle' in $file"
  fi
}

link_installer_utilities() {
  local destination="$1" utility source
  mkdir -p "$destination"
  for utility in basename cat chmod cmp dirname grep head install mkdir mktemp rm rmdir sed; do
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
            if [ "${RUNTIME_TEST_PI_LIST_FAILURE:-0}" = "1" ]; then
              printf 'mock pi list stderr\n' >&2
              exit 73
            fi
            printf 'User packages:\n'
            if [ -n "${RUNTIME_TEST_PI_LIST_SOURCE:-}" ] &&
              [ ! -f "$RUNTIME_TEST_STATE/listed-source-removed" ]; then
              printf '  %s\n    /mock/listed\n' "$RUNTIME_TEST_PI_LIST_SOURCE"
            fi
            if [ -f "$RUNTIME_TEST_STATE/pi-installed" ]; then
              printf '  %s\n    /mock/installed\n' "$RUNTIME_TEST_SOURCE"
            fi
            ;;
          update)
            [ "$#" -eq 2 ] && [ "$1" = "--extension" ] &&
              [ "$2" = "$RUNTIME_TEST_SOURCE" ] ||
              fail "unexpected pi update arguments: $*"
            [ -f "$RUNTIME_TEST_STATE/pi-installed" ] ||
              fail "pi update ran before pi install"
            printf 'exec:pi update:%s\n' "$2" >> "$RUNTIME_TEST_LOG"
            ;;
          remove)
            [ "$#" -eq 1 ] && [ -n "${RUNTIME_TEST_PI_LIST_SOURCE:-}" ] &&
              [ "$1" = "$RUNTIME_TEST_PI_LIST_SOURCE" ] ||
              fail "unexpected pi remove arguments: $*"
            printf 'exec:pi remove:%s\n' "$1" >> "$RUNTIME_TEST_LOG"
            : > "$RUNTIME_TEST_STATE/listed-source-removed"
            ;;
          install)
            [ "$#" -eq 1 ] && [ "$1" = "$RUNTIME_TEST_SOURCE" ] ||
              fail "unexpected pi install arguments: $*"
            printf 'exec:pi install:%s\n' "$1" >> "$RUNTIME_TEST_LOG"
            : > "$RUNTIME_TEST_STATE/pi-installed"
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
set -euo pipefail
printf '%s\n' "${RUNTIME_TEST_UNAME:?}"
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

write_lockf_mock() {
  local destination="$1"
  cat > "$destination/lockf" <<'EOF'
#!/bin/bash
set -euo pipefail
: > "${RUNTIME_TEST_MARKERS:?}/invoked-lockf"
exit 99
EOF
  chmod 755 "$destination/lockf"
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

setup_fixture() {
  local root="$1" system_runtimes="$2" with_lockf="$3"

  mkdir -p \
    "$root/system-bin" \
    "$root/home" \
    "$root/state" \
    "$root/markers"
  : > "$root/mise.log"
  link_installer_utilities "$root/common-bin"
  write_prerequisite_mocks "$root/system-bin"
  write_mise_mock "$root/system-bin/mise"
  write_stale_shims "$root/home/.local/share/mise/shims"
  if [ "$system_runtimes" = "yes" ]; then
    write_system_runtime_mocks "$root/system-bin"
  fi
  if [ "$with_lockf" = "yes" ]; then
    write_lockf_mock "$root/system-bin"
  fi
}

run_installer() {
  local root="$1" system_name="$2" pi_list_failure="$3" pi_list_source="${4:-}"

  env -i \
    HOME="$root/home" \
    PATH="$root/system-bin:$root/common-bin" \
    COPILOT_HOME="$root/copilot-home" \
    PI_CODING_AGENT_DIR="$root/pi-agent" \
    BIN_DIR="$root/local-bin" \
    RUNTIME_TEST_LOG="$root/mise.log" \
    RUNTIME_TEST_MARKERS="$root/markers" \
    RUNTIME_TEST_PI_LIST_FAILURE="$pi_list_failure" \
    RUNTIME_TEST_PI_LIST_SOURCE="$pi_list_source" \
    RUNTIME_TEST_REPO_ROOT="$REPO_ROOT" \
    RUNTIME_TEST_SOURCE="$SUBAGENTS_SOURCE" \
    RUNTIME_TEST_STATE="$root/state" \
    RUNTIME_TEST_UNAME="$system_name" \
    /bin/bash "$INSTALLER"
}

assert_no_runtime_markers() {
  local name="$1" root="$2" runtime_marker

  for runtime_marker in "$root/markers"/*; do
    [ ! -e "$runtime_marker" ] ||
      fail "$name invoked unconfigured runtime marker $runtime_marker"
  done
}

assert_no_agent_stack_mutations() {
  local name="$1" root="$2"

  assert_count 0 "exec:pi install:$SUBAGENTS_SOURCE" "$root/mise.log"
  assert_count 0 "exec:pi update:$SUBAGENTS_SOURCE" "$root/mise.log"
  if grep -q '^exec:pi remove:' "$root/mise.log"; then
    fail "$name removed Pi packages before validating package state"
  fi
  assert_count 0 "exec:npx skills" "$root/mise.log"
  assert_count 0 "exec:herdr integration pi" "$root/mise.log"
  assert_count 0 "exec:herdr integration copilot" "$root/mise.log"
  [ ! -e "$root/pi-agent/extensions/reviewer-git.ts" ] ||
    fail "$name installed the repository-owned extension before validating package state"
  [ ! -e "$root/pi-agent/agents/reviewer.md" ] ||
    fail "$name installed profiles before validating package state"
  [ ! -e "$root/copilot-home" ] ||
    fail "$name installed the Copilot integration before validating package state"
  [ ! -e "$root/local-bin" ] ||
    fail "$name installed wrappers before validating package state"
}

assert_reviewer_profile() {
  local name="$1" root="$2"
  local expected="$root/expected-reviewer.md"

  sed "s|@REVIEWER_GIT_EXTENSION@|$root/pi-agent/extensions/reviewer-git.ts|g" \
    "$REPO_ROOT/pi/agent-stack/profiles/reviewer.md" > "$expected"
  cmp -s "$expected" "$root/pi-agent/agents/reviewer.md" ||
    fail "$name did not install the rendered reviewer profile"
  assert_not_contains "@REVIEWER_GIT_EXTENSION@" "$root/pi-agent/agents/reviewer.md"
}

run_success_scenario() {
  local name="$1" system_runtimes="$2" system_name="$3" with_lockf="$4"
  local root="$tmp/$name"
  local log="$root/mise.log"
  local first_output="$root/first.out"
  local second_output="$root/second.out"

  setup_fixture "$root" "$system_runtimes" "$with_lockf"

  if ! run_installer "$root" "$system_name" 0 >"$first_output" 2>&1; then
    cat "$first_output" >&2
    fail "$name first installer run failed"
  fi

  if ! run_installer "$root" "$system_name" 0 >"$second_output" 2>&1; then
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
  assert_count 1 "exec:pi install:$SUBAGENTS_SOURCE" "$log"
  assert_count 1 "exec:pi update:$SUBAGENTS_SOURCE" "$log"
  assert_contains "updated $SUBAGENTS_SOURCE" "$second_output"
  if grep -q '^exec:pi remove:' "$log"; then
    fail "$name removed a Pi package without a superseded source"
  fi
  assert_count 2 "exec:herdr --version" "$log"
  assert_count 2 "exec:herdr integration pi" "$log"
  assert_count 2 "exec:herdr integration copilot" "$log"

  assert_no_runtime_markers "$name" "$root"

  cmp -s \
    "$REPO_ROOT/pi/agent-stack/extensions/reviewer-git.ts" \
    "$root/pi-agent/extensions/reviewer-git.ts" ||
    fail "$name did not install the repository-owned extension"
  assert_reviewer_profile "$name" "$root"
  [ -d "$root/copilot-home" ] ||
    fail "$name did not honor COPILOT_HOME"
  assert_contains "installed reviewer-git.ts" "$first_output"
  assert_contains "reviewer-git.ts is up to date" "$second_output"
  assert_contains "reviewer.md is up to date" "$second_output"

  if [ "$system_name" = "Darwin" ]; then
    cmp -s "$REPO_ROOT/pi/agent-stack/bin/xbuild" "$root/local-bin/xbuild" ||
      fail "$name did not install xbuild"
    assert_contains "installed xbuild" "$first_output"
    assert_contains "xbuild is up to date" "$second_output"
  else
    [ ! -e "$root/local-bin/xbuild" ] ||
      fail "$name unexpectedly installed xbuild on $system_name"
  fi
}

run_darwin_no_lockf() {
  local name="darwin-without-lockf"
  local root="$tmp/$name"
  local output="$root/install.out"
  local status

  setup_fixture "$root" "no" "no"

  set +e
  run_installer "$root" "Darwin" 0 >"$output" 2>&1
  status=$?
  set -e

  [ "$status" -ne 0 ] || fail "$name unexpectedly succeeded"
  assert_contains "macOS lockf is required by xbuild" "$output"
  assert_not_contains "Installing mise-managed Node, Pi, and Herdr" "$output"
  [ ! -s "$root/mise.log" ] ||
    fail "$name invoked mise before rejecting missing lockf"
  [ ! -e "$root/pi-agent" ] ||
    fail "$name modified the Pi agent directory before rejecting missing lockf"
  [ ! -e "$root/copilot-home" ] ||
    fail "$name modified COPILOT_HOME before rejecting missing lockf"
  [ ! -e "$root/local-bin" ] ||
    fail "$name modified BIN_DIR before rejecting missing lockf"
  [ ! -e "$root/state/pi-installed" ] ||
    fail "$name modified Pi package state before rejecting missing lockf"
  assert_no_runtime_markers "$name" "$root"
}

run_pi_list_failure() {
  local name="pi-list-failure"
  local root="$tmp/$name"
  local output="$root/install.out"
  local status

  setup_fixture "$root" "no" "no"

  set +e
  run_installer "$root" "Linux" 1 >"$output" 2>&1
  status=$?
  set -e

  [ "$status" -ne 0 ] || fail "$name unexpectedly succeeded"
  assert_contains "mock pi list stderr" "$output"
  assert_contains "failed to inspect installed Pi packages" "$output"
  assert_not_contains "installed $SUBAGENTS_SOURCE" "$output"
  assert_count 1 "exec:pi list" "$root/mise.log"
  assert_no_agent_stack_mutations "$name" "$root"
  [ ! -e "$root/state/pi-installed" ] ||
    fail "$name changed Pi package state after inspection failed"
  assert_no_runtime_markers "$name" "$root"
}

run_migration() {
  local name="$1" listed_source="$2"
  local root="$tmp/$name"
  local log="$root/mise.log"
  local first_output="$root/first.out"
  local second_output="$root/second.out"
  local legacy_dir="$root/pi-agent/herdr-subagents/agents"

  setup_fixture "$root" "no" "no"
  mkdir -p "$legacy_dir"
  printf 'legacy reviewer\n' > "$legacy_dir/reviewer.md"
  printf 'legacy worker\n' > "$legacy_dir/worker.md"

  if ! run_installer "$root" "Linux" 0 "$listed_source" >"$first_output" 2>&1; then
    cat "$first_output" >&2
    fail "$name first installer run failed"
  fi
  if ! run_installer "$root" "Linux" 0 "$listed_source" >"$second_output" 2>&1; then
    cat "$second_output" >&2
    fail "$name second installer run failed"
  fi

  assert_count 1 "exec:pi remove:$listed_source" "$log"
  assert_count 1 "exec:pi install:$SUBAGENTS_SOURCE" "$log"
  assert_count 1 "exec:pi update:$SUBAGENTS_SOURCE" "$log"
  assert_contains "removed $listed_source" "$first_output"
  assert_contains "removed legacy profile $legacy_dir/reviewer.md" "$first_output"
  assert_contains "updated $SUBAGENTS_SOURCE" "$second_output"
  [ ! -e "$root/pi-agent/herdr-subagents" ] ||
    fail "$name left the legacy profile directory behind"
  assert_reviewer_profile "$name" "$root"
  assert_no_runtime_markers "$name" "$root"
}

run_success_scenario "qualifying-system-runtimes" "yes" "Linux" "no"
run_success_scenario "absent-system-runtimes" "no" "Linux" "no"
run_success_scenario "darwin-with-lockf" "no" "Darwin" "yes"
run_darwin_no_lockf
run_pi_list_failure
run_migration "legacy-maxedapps-migration" "$LEGACY_SOURCE"
run_migration "pinned-version-migration" "npm:pi-subagents@0.73.1"

printf 'installer mise runtime tests passed\n'
