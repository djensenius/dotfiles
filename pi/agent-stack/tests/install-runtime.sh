#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$DIR/../install.sh"
REPO_ROOT="$(cd "$DIR/../../.." && pwd)"
SUBAGENTS_SOURCE="npm:pi-subagents"
LEGACY_SOURCE="git:github.com/maxedapps/pi-subagents-herdr@3af3865a58ea4c551c3ea7b099fe8a9ea42cba83"
MCP_ADAPTER_SOURCE="npm:pi-mcp-adapter"
PI_HERDR_SOURCE="npm:@narumitw/pi-herdr"
MANAGED_PACKAGE_SOURCES=(
  "npm:pi-catppuccin-footer"
  "npm:@plannotator/pi-extension"
  "npm:pi-web-access"
  "npm:pi-browser-harness"
  "npm:pi-memory"
  "$PI_HERDR_SOURCE"
)
PREINSTALLED_MANAGED_PACKAGE="npm:pi-web-access"
UNMANAGED_PACKAGE_SOURCE="npm:some-local-tool"

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

assert_not_exists() {
  local path="$1"
  [ ! -e "$path" ] && [ ! -L "$path" ] ||
    fail "expected path to be absent: $path"
}

assert_symlink_to() {
  local expected="$1" path="$2"
  [ -L "$path" ] || fail "expected symlink: $path"
  [ "$(readlink "$path")" = "$expected" ] ||
    fail "expected $path to link to $expected, found $(readlink "$path")"
}

sanitize_source() {
  printf '%s' "$1" | sed 's/[^A-Za-z0-9_.-]/_/g'
}

mark_package_installed() {
  local root="$1" source="$2"
  : > "$root/state/package-$(sanitize_source "$source")"
}

assert_json() {
  local file="$1" expression="$2" message="$3"
  # shellcheck disable=SC2016
  node -e '
    const fs = require("fs");
    const file = process.argv[1];
    const expression = process.argv[2];
    const value = JSON.parse(fs.readFileSync(file, "utf8"));
    if (!Function("value", `return (${expression});`)(value)) process.exit(1);
  ' "$file" "$expression" || fail "$message"
}

link_installer_utilities() {
  local destination="$1" utility source
  mkdir -p "$destination"
  for utility in awk basename cat chmod cmp cp dirname grep head install ln mkdir mktemp mv rm rmdir sed; do
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

sanitize_source() {
  printf '%s' "$1" | sed 's/[^A-Za-z0-9_.-]/_/g'
}

is_managed_package_source() {
  grep -Fxq "$1" <<<"${RUNTIME_TEST_MANAGED_PACKAGE_SOURCES:?}"
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
          "$RUNTIME_TEST_REPO_ROOT/pi/agent-stack/bin/merge-json.mjs")
            [ -x "${RUNTIME_TEST_REAL_NODE:?}" ] ||
              fail "real node is unavailable for merge-json helper"
            [ "$#" -ge 3 ] || fail "unexpected merge-json arguments: $*"
            printf 'exec:node merge-json:%s\n' "$(basename "$2")" >> "$RUNTIME_TEST_LOG"
            "$RUNTIME_TEST_REAL_NODE" "$@"
            ;;
          "$RUNTIME_TEST_REPO_ROOT/pi/agent-stack/bin/migrate-mcp-adapter.mjs")
            [ -x "${RUNTIME_TEST_REAL_NODE:?}" ] ||
              fail "real node is unavailable for MCP adapter migration helper"
            [ "$#" -eq 3 ] || fail "unexpected MCP adapter migration arguments: $*"
            printf 'exec:node migrate-mcp-adapter:%s\n' "$(basename "$2")" >> "$RUNTIME_TEST_LOG"
            "$RUNTIME_TEST_REAL_NODE" "$@"
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
          case "$*" in
            "-y skills add herdrdev/herdr --skill herdr --agent pi github-copilot -g -y")
              printf 'exec:npx skills add\n' >> "$RUNTIME_TEST_LOG"
              ;;
            "-y skills remove herdr -g -y")
              rm -rf \
                "$HOME/.agents/skills/herdr" \
                "$HOME/.pi/agent/skills/herdr" \
                "$HOME/.copilot/skills/herdr"
              printf 'exec:npx skills remove\n' >> "$RUNTIME_TEST_LOG"
              ;;
            *)
              fail "unexpected npx arguments: $*"
              ;;
          esac
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
            # Mirror real `pi list` output: styled section headers, a
            # " (filtered)" display suffix, and a project scope the installer
            # must ignore.
            printf '\033[1mUser packages:\033[22m\n'
            printf '  %s\n    /mock/unmanaged\n' "$RUNTIME_TEST_UNMANAGED_PACKAGE_SOURCE"
            if [ -n "${RUNTIME_TEST_PI_LIST_SOURCE:-}" ] &&
              [ ! -f "$RUNTIME_TEST_STATE/listed-source-removed" ]; then
              printf '  %s\n    /mock/listed\n' "$RUNTIME_TEST_PI_LIST_SOURCE"
            fi
            while IFS= read -r managed_source; do
              [ -n "$managed_source" ] || continue
              marker="$RUNTIME_TEST_STATE/package-$(sanitize_source "$managed_source")"
              if [ -s "$marker" ]; then
                # A version-pinned entry must count as already installed.
                printf '  %s@%s\n    /mock/managed\n' "$managed_source" "$(cat "$marker")"
              elif [ -f "$marker" ]; then
                printf '  %s\n    /mock/managed\n' "$managed_source"
              fi
            done <<<"$RUNTIME_TEST_MANAGED_PACKAGE_SOURCES"
            if [ -f "$RUNTIME_TEST_STATE/pi-installed" ]; then
              printf '  %s%s\n    /mock/installed\n' \
                "$RUNTIME_TEST_SOURCE" "${RUNTIME_TEST_PI_LIST_SUFFIX:-}"
            fi
            printf '\n\033[1mProject packages:\033[22m\n'
            printf '  npm:pi-subagents@0.1.0\n    /mock/project-pinned\n'
            printf '  git:github.com/maxedapps/pi-subagents-herdr@2222222222222222222222222222222222222222\n'
            printf '    /mock/project-legacy\n'
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
            [ "$#" -eq 1 ] || fail "unexpected pi install arguments: $*"
            if [ "$1" = "$RUNTIME_TEST_SOURCE" ]; then
              : > "$RUNTIME_TEST_STATE/pi-installed"
            elif is_managed_package_source "$1"; then
              : > "$RUNTIME_TEST_STATE/package-$(sanitize_source "$1")"
            else
              fail "unexpected pi install arguments: $*"
            fi
            printf 'exec:pi install:%s\n' "$1" >> "$RUNTIME_TEST_LOG"
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
        elif [ "$#" -eq 1 ] && [ "$1" = "--skill" ]; then
          printf 'exec:herdr --skill\n' >> "$RUNTIME_TEST_LOG"
          if [ "${RUNTIME_TEST_HERDR_SKILL_FAILURE:-0}" = "1" ]; then
            printf 'mock herdr skill failure\n' >&2
            exit 74
          fi
          cat <<'SKILL'
---
name: herdr
description: Generated Herdr skill
---
SKILL
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

write_brew_mock() {
  local destination="$1"
  cat > "$destination/brew" <<'EOF'
#!/bin/bash
set -euo pipefail
[ "${HOMEBREW_NO_AUTO_UPDATE:-}" = "1" ] || exit 9
[ "${HOMEBREW_NO_INSTALL_CLEANUP:-}" = "1" ] || exit 9
[ "${HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK:-}" = "1" ] || exit 9
[ "$#" -eq 2 ] && [ "$1" = "install" ] || exit 9
case "$2" in
  backlog-md|djensenius/tap/backlog-sync) ;;
  *) exit 9 ;;
esac
printf 'exec:brew install:%s\n' "$2" >> "${RUNTIME_TEST_LOG:?}"
EOF
  chmod 755 "$destination/brew"
}

write_failing_brew_mock() {
  local destination="$1"
  cat > "$destination/brew" <<'EOF'
#!/bin/bash
set -euo pipefail
[ "${HOMEBREW_NO_AUTO_UPDATE:-}" = "1" ] || exit 9
[ "${HOMEBREW_NO_INSTALL_CLEANUP:-}" = "1" ] || exit 9
[ "${HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK:-}" = "1" ] || exit 9
[ "$#" -eq 2 ] && [ "$1" = "install" ] || exit 9
case "$2" in
  backlog-md|djensenius/tap/backlog-sync) ;;
  *) exit 9 ;;
esac
printf 'exec:brew install:%s\n' "$2" >> "${RUNTIME_TEST_LOG:?}"
exit 66
EOF
  chmod 755 "$destination/brew"
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
  mark_package_installed "$root" "$PREINSTALLED_MANAGED_PACKAGE"
  printf '0.32.0' > "$root/state/package-$(sanitize_source "$PREINSTALLED_MANAGED_PACKAGE")"
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
  local pi_agent_dir="${RUNTIME_TEST_PI_AGENT_DIR:-$root/pi-agent}"
  local copilot_home="${RUNTIME_TEST_COPILOT_HOME:-$root/copilot-home}"
  local managed_package_sources real_node

  managed_package_sources="$(printf '%s\n' "${MANAGED_PACKAGE_SOURCES[@]}")"
  real_node="$(command -v node || true)"

  env -i \
    HOME="$root/home" \
    PATH="$root/system-bin:$root/common-bin" \
    COPILOT_HOME="$copilot_home" \
    PI_CODING_AGENT_DIR="$pi_agent_dir" \
    BIN_DIR="$root/local-bin" \
    RUNTIME_TEST_LOG="$root/mise.log" \
    RUNTIME_TEST_MANAGED_PACKAGE_SOURCES="$managed_package_sources" \
    RUNTIME_TEST_MARKERS="$root/markers" \
    RUNTIME_TEST_HERDR_SKILL_FAILURE="${RUNTIME_TEST_HERDR_SKILL_FAILURE:-0}" \
    RUNTIME_TEST_PI_LIST_FAILURE="$pi_list_failure" \
    RUNTIME_TEST_PI_LIST_SOURCE="$pi_list_source" \
    RUNTIME_TEST_PI_LIST_SUFFIX="${RUNTIME_TEST_PI_LIST_SUFFIX:-}" \
    RUNTIME_TEST_REAL_NODE="$real_node" \
    RUNTIME_TEST_REPO_ROOT="$REPO_ROOT" \
    RUNTIME_TEST_SOURCE="$SUBAGENTS_SOURCE" \
    RUNTIME_TEST_UNMANAGED_PACKAGE_SOURCE="$UNMANAGED_PACKAGE_SOURCE" \
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
  local name="$1" root="$2" package_source

  assert_count 0 "exec:pi install:$SUBAGENTS_SOURCE" "$root/mise.log"
  assert_count 0 "exec:pi update:$SUBAGENTS_SOURCE" "$root/mise.log"
  for package_source in "${MANAGED_PACKAGE_SOURCES[@]}"; do
    assert_count 0 "exec:pi install:$package_source" "$root/mise.log"
  done
  if grep -q '^exec:pi remove:' "$root/mise.log"; then
    fail "$name removed Pi packages before validating package state"
  fi
  assert_count 0 "exec:npx skills add" "$root/mise.log"
  assert_count 0 "exec:npx skills remove" "$root/mise.log"
  assert_count 0 "exec:herdr integration pi" "$root/mise.log"
  assert_count 0 "exec:herdr integration copilot" "$root/mise.log"
  assert_count 0 "exec:herdr --skill" "$root/mise.log"
  [ ! -e "$root/pi-agent/settings.json" ] ||
    fail "$name installed shared settings before validating package state"
  [ ! -e "$root/pi-agent/mcp.json" ] ||
    fail "$name installed MCP config before validating package state"
  [ ! -e "$root/pi-agent/catppuccin-footer.json" ] ||
    fail "$name installed footer config before validating package state"
  [ ! -e "$root/pi-agent/extensions/reviewer-git.ts" ] ||
    fail "$name installed the repository-owned extension before validating package state"
  [ ! -e "$root/pi-agent/extensions/subagent-status.ts" ] ||
    fail "$name installed the subagent status extension before validating package state"
  [ ! -e "$root/pi-agent/agents/reviewer.md" ] ||
    fail "$name installed profiles before validating package state"
  [ ! -e "$root/copilot-home" ] ||
    fail "$name installed the Copilot integration before validating package state"
  [ ! -e "$root/local-bin" ] ||
    fail "$name installed wrappers before validating package state"
}

assert_reviewer_profile() {
  local name="$1" agent_dir="$2"

  assert_symlink_to \
    "$REPO_ROOT/pi/agent-stack/profiles/reviewer.md" \
    "$agent_dir/agents/reviewer.md"
  grep -Fxq "extensions: ../extensions/reviewer-git.ts" \
    "$agent_dir/agents/reviewer.md" ||
    fail "$name reviewer profile does not load reviewer-git.ts relatively"
  # pi-subagents resolves ../ entries from the agent file's directory.
  assert_symlink_to \
    "$REPO_ROOT/pi/agent-stack/extensions/reviewer-git.ts" \
    "$agent_dir/agents/../extensions/reviewer-git.ts"
}

assert_shared_config() {
  local name="$1" agent_dir="$2" profile

  assert_json "$agent_dir/settings.json" \
    'value.localOnly === true && value.lastChangelogVersion === "0.1.0" && value.packages[0] === "keep"' \
    "$name settings merge dropped local keys"
  assert_json "$agent_dir/settings.json" \
    'value.defaultProvider === "github-copilot" && value.defaultModel === "gpt-5.5" && value.defaultThinkingLevel === "medium" && value.theme === "system" && value.tuiMode === "fullscreen" && value.quietStartup === "header"' \
    "$name settings merge did not apply shared top-level values"
  assert_json "$agent_dir/settings.json" \
    'value.subagents.localSetting === "preserved" && value.subagents.agentOverrides.worker.model === "github-copilot/gpt-5.5" && value.subagents.agentOverrides.scout.model === "github-copilot/gpt-5.4-mini" && value.subagents.agentOverrides.researcher.model === "github-copilot/gemini-3.8-flash" && value.subagents.agentOverrides.reviewer.model === "github-copilot/claude-opus-5.5" && value.subagents.agentOverrides.oracle.model === "github-copilot/claude-opus-5.5" && value.subagents.agentOverrides.localOnly.description === "preserved"' \
    "$name settings merge did not preserve or override nested subagent values"
  assert_json "$agent_dir/extensions/subagent/config.json" \
    'value.fleetView === true && value.asyncWidget === false && value.authorityPolicy.inspectorOpen === "auto" && value.authorityPolicy.projectOpen === "confirm"' \
    "$name subagent config merge did not preserve local policy and apply shared rich-view defaults"
  assert_json "$agent_dir/mcp.json" \
    'value.mcpServers.other.command === "other" && value.mcpServers.playwright.description.includes("Playwright") && value.mcpServers.playwright.command === "npx" && value.mcpServers.playwright.args.join(" ") === "-y @playwright/mcp@latest --browser firefox" && value.mcpServers.context7.description.includes("Context7") && value.mcpServers.context7.command === "npx" && value.mcpServers.context7.args.join(" ") === "-y @upstash/context7-mcp@latest"' \
    "$name MCP merge did not preserve other servers and configure shared servers"
  assert_symlink_to \
    "$REPO_ROOT/pi/agent-stack/catppuccin-footer.json" \
    "$agent_dir/catppuccin-footer.json"
  for profile in council-gpt.md council-claude.md council-gemini.md; do
    assert_symlink_to \
      "$REPO_ROOT/pi/agent-stack/profiles/$profile" \
      "$agent_dir/agents/$profile"
  done
}

run_success_scenario() {
  local name="$1" system_runtimes="$2" system_name="$3" with_lockf="$4"
  local RUNTIME_TEST_PI_LIST_SUFFIX="${5:-}"
  local root="$tmp/$name"
  local log="$root/mise.log"
  local first_output="$root/first.out"
  local second_output="$root/second.out"
  local package_source

  setup_fixture "$root" "$system_runtimes" "$with_lockf"
  mkdir -p \
    "$root/home/.agents/skills/herdr" \
    "$root/pi-agent/agents" \
    "$root/pi-agent/extensions/subagent" \
    "$root/pi-agent/skills"
  printf 'standalone herdr skill\n' > "$root/home/.agents/skills/herdr/SKILL.md"
  ln -s "$root/home/.agents/skills/herdr" "$root/pi-agent/skills/herdr"
  printf 'standalone herdr integration\n' > "$root/pi-agent/extensions/herdr-agent-state.ts"
  cat > "$root/pi-agent/settings.json" <<'JSON'
{
  "lastChangelogVersion": "0.1.0",
  "defaultProvider": "old-provider",
  "packages": ["keep"],
  "localOnly": true,
  "subagents": {
    "localSetting": "preserved",
    "agentOverrides": {
      "worker": { "model": "old-provider/old-model" },
      "localOnly": { "description": "preserved" }
    }
  }
}
JSON
  cat > "$root/pi-agent/extensions/subagent/config.json" <<'JSON'
{
  "fleetView": false,
  "asyncWidget": true,
  "authorityPolicy": {
    "projectOpen": "confirm"
  }
}
JSON
  cat > "$root/pi-agent/mcp.json" <<'JSON'
{
  "mcpServers": {
    "other": {
      "command": "other"
    },
    "playwright": {
      "command": "old-playwright"
    }
  }
}
JSON
  cp "$REPO_ROOT/pi/agent-stack/catppuccin-footer.json" \
    "$root/pi-agent/catppuccin-footer.json"
  cp "$REPO_ROOT/pi/agent-stack/extensions/reviewer-git.ts" \
    "$root/pi-agent/extensions/reviewer-git.ts"
  cp "$REPO_ROOT/pi/agent-stack/profiles/reviewer.md" \
    "$root/pi-agent/agents/reviewer.md"

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
  assert_count 0 "exec:npx skills add" "$log"
  assert_count 2 "exec:npx skills remove" "$log"
  assert_count 2 "exec:pi --version" "$log"
  assert_count 2 "exec:pi list" "$log"
  assert_count 1 "exec:pi install:$SUBAGENTS_SOURCE" "$log"
  assert_count 1 "exec:pi update:$SUBAGENTS_SOURCE" "$log"
  for package_source in "${MANAGED_PACKAGE_SOURCES[@]}"; do
    if [ "$package_source" = "$PREINSTALLED_MANAGED_PACKAGE" ]; then
      assert_count 0 "exec:pi install:$package_source" "$log"
      assert_contains "$package_source is already installed" "$first_output"
    else
      assert_count 1 "exec:pi install:$package_source" "$log"
      assert_contains "$package_source is already installed" "$second_output"
    fi
  done
  assert_count 0 "exec:pi remove:$UNMANAGED_PACKAGE_SOURCE" "$log"
  assert_contains "updated $SUBAGENTS_SOURCE" "$second_output"
  if grep -q '^exec:pi remove:' "$log"; then
    fail "$name removed a Pi package without a superseded source"
  fi
  assert_count 2 "exec:herdr --version" "$log"
  assert_count 2 "exec:herdr --skill" "$log"
  assert_count 0 "exec:herdr integration pi" "$log"
  assert_count 2 "exec:herdr integration copilot" "$log"

  assert_no_runtime_markers "$name" "$root"

  assert_symlink_to \
    "$REPO_ROOT/pi/agent-stack/extensions/reviewer-git.ts" \
    "$root/pi-agent/extensions/reviewer-git.ts"
  assert_symlink_to \
    "$REPO_ROOT/pi/agent-stack/extensions/subagent-status.ts" \
    "$root/pi-agent/extensions/subagent-status.ts"
  [ ! -e "$root/pi-agent/extensions/herdr-agent-state.ts" ] ||
    fail "$name did not remove the standalone Herdr Pi lifecycle integration"
  assert_not_exists "$root/home/.agents/skills/herdr"
  assert_not_exists "$root/pi-agent/skills/herdr"
  assert_contains "description: Generated Herdr skill" "$root/copilot-home/skills/herdr/SKILL.md"
  [ ! -L "$root/copilot-home/skills/herdr" ] ||
    fail "$name left Copilot's Herdr skill linked to the removed canonical skill"
  assert_reviewer_profile "$name" "$root/pi-agent"
  assert_shared_config "$name" "$root/pi-agent"
  [ -d "$root/copilot-home" ] ||
    fail "$name did not honor COPILOT_HOME"
  assert_contains "linked reviewer-git.ts" "$first_output"
  assert_contains "reviewer-git.ts is linked" "$second_output"
  assert_contains "linked subagent-status.ts" "$first_output"
  assert_contains "subagent-status.ts is linked" "$second_output"
  assert_contains "settings.json is up to date" "$second_output"
  assert_contains "mcp.json is up to date" "$second_output"
  assert_contains "catppuccin-footer.json is linked" "$second_output"
  assert_contains "reviewer.md is linked" "$second_output"
  assert_contains "council-gpt.md is linked" "$second_output"
  assert_contains "council-claude.md is linked" "$second_output"
  assert_contains "council-gemini.md is linked" "$second_output"
  assert_contains "On non-Homebrew systems, install the Backlog.md CLI and backlog-sync first" "$first_output"
  assert_contains "npm i -g backlog.md" "$first_output"
  assert_contains "Install backlog-sync from https://github.com/djensenius/backlog-sync" "$first_output"
  assert_contains "cp \"$REPO_ROOT/pi/agent-stack/templates/AGENTS.md\" ./AGENTS.md" "$first_output"
  assert_contains "backlog init --backlog-dir .backlog" "$first_output"
  assert_contains "backlog config set autoCommit true" "$first_output"
  assert_contains "backlog config set checkActiveBranches true" "$first_output"
  assert_contains "backlog agents --update-instructions" "$first_output"
  assert_contains "cp \"$REPO_ROOT/pi/agent-stack/templates/backlog.instructions.md\" .github/instructions/" "$first_output"
  assert_contains "Add this two-line Backlog section to the repo's .github/copilot-instructions.md" "$first_output"
  assert_contains "## Backlog.md files" "$first_output"
  assert_contains "Copilot code review must not review or comment on Backlog.md task files; \`.github/instructions/backlog.instructions.md\` owns the path rule." "$first_output"
  assert_contains "ruleset requiring CI before merge" "$first_output"

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

run_darwin_with_brew_installs_backlog_md_and_sync() {
  local name="darwin-with-brew-installs-backlog-md-and-sync"
  local root="$tmp/$name"
  local output="$root/install.out"

  setup_fixture "$root" "no" "yes"
  write_brew_mock "$root/system-bin"
  if ! run_installer "$root" "Darwin" 0 >"$output" 2>&1; then
    cat "$output" >&2
    fail "$name installer run failed"
  fi

  assert_count 1 "exec:brew install:backlog-md" "$root/mise.log"
  assert_count 1 "exec:brew install:djensenius/tap/backlog-sync" "$root/mise.log"
  assert_contains "Installing Backlog.md CLI" "$output"
  assert_contains "installed backlog-md" "$output"
  assert_contains "Installing backlog-sync" "$output"
  assert_contains "installed backlog-sync" "$output"
}

run_darwin_with_existing_backlog_tools_skips_brew() {
  local name="darwin-with-existing-backlog-tools-skips-brew"
  local root="$tmp/$name"
  local output="$root/install.out"
  local tool

  setup_fixture "$root" "no" "yes"
  write_brew_mock "$root/system-bin"
  for tool in backlog backlog-sync; do
    cat > "$root/system-bin/$tool" <<'EOF'
#!/bin/bash
set -euo pipefail
exit 0
EOF
    chmod 755 "$root/system-bin/$tool"
  done

  if ! run_installer "$root" "Darwin" 0 >"$output" 2>&1; then
    cat "$output" >&2
    fail "$name installer run failed"
  fi

  assert_count 0 "exec:brew install:backlog-md" "$root/mise.log"
  assert_count 0 "exec:brew install:djensenius/tap/backlog-sync" "$root/mise.log"
  if grep -Fq "exec:brew install:" "$root/mise.log"; then
    fail "$name unexpectedly invoked brew"
  fi
  assert_contains "backlog CLI is already installed" "$output"
  assert_contains "backlog-sync is already installed" "$output"
  assert_not_contains "Installing Backlog.md CLI" "$output"
  assert_not_contains "Installing backlog-sync" "$output"
}

run_darwin_with_failing_brew_warns_and_continues() {
  local name="darwin-with-failing-brew-warns-and-continues"
  local root="$tmp/$name"
  local output="$root/install.out"
  local status

  setup_fixture "$root" "no" "yes"
  write_failing_brew_mock "$root/system-bin"

  set +e
  run_installer "$root" "Darwin" 0 >"$output" 2>&1
  status=$?
  set -e

  [ "$status" -eq 0 ] || {
    cat "$output" >&2
    fail "$name installer exited with $status"
  }
  assert_count 1 "exec:brew install:backlog-md" "$root/mise.log"
  assert_count 1 "exec:brew install:djensenius/tap/backlog-sync" "$root/mise.log"
  assert_contains "Installing Backlog.md CLI" "$output"
  assert_contains "Installing backlog-sync" "$output"
  assert_contains "failed to install backlog-md; continuing without the backlog CLI" "$output"
  assert_contains "failed to install backlog-sync; continuing without backlog-sync" "$output"
  assert_contains "Agent stack installed." "$output"
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

run_invalid_settings_json() {
  local name="invalid-settings-json"
  local root="$tmp/$name"
  local output="$root/install.out"
  local status

  setup_fixture "$root" "no" "no"
  mkdir -p "$root/pi-agent"
  printf '{ invalid settings json\n' > "$root/pi-agent/settings.json"

  set +e
  run_installer "$root" "Linux" 0 >"$output" 2>&1
  status=$?
  set -e

  [ "$status" -ne 0 ] || fail "$name unexpectedly succeeded"
  assert_contains "invalid JSON in $root/pi-agent/settings.json" "$output"
  assert_contains "failed to merge settings.json" "$output"
  grep -Fxq '{ invalid settings json' "$root/pi-agent/settings.json" ||
    fail "$name changed invalid settings before aborting"
  assert_count 1 "exec:node merge-json:settings.json" "$root/mise.log"
  assert_count 0 "exec:node merge-json:config.json" "$root/mise.log"
  assert_count 0 "exec:pi install:$SUBAGENTS_SOURCE" "$root/mise.log"
  assert_count 0 "exec:pi update:$SUBAGENTS_SOURCE" "$root/mise.log"
  [ ! -e "$root/pi-agent/mcp.json" ] ||
    fail "$name installed MCP config after invalid settings"
  [ ! -e "$root/pi-agent/catppuccin-footer.json" ] ||
    fail "$name installed footer config after invalid settings"
  [ ! -e "$root/pi-agent/extensions/reviewer-git.ts" ] ||
    fail "$name installed extension after invalid settings"
  [ ! -e "$root/pi-agent/agents/reviewer.md" ] ||
    fail "$name installed profiles after invalid settings"
  assert_no_runtime_markers "$name" "$root"
}

run_herdr_skill_generation_failure() {
  local name="herdr-skill-generation-failure"
  local root="$tmp/$name"
  local output="$root/install.out"
  local status

  setup_fixture "$root" "no" "no"
  mkdir -p \
    "$root/home/.agents/skills/herdr" \
    "$root/pi-agent/skills" \
    "$root/copilot-home/skills/herdr"
  printf 'working standalone herdr skill\n' > "$root/home/.agents/skills/herdr/SKILL.md"
  ln -s "$root/home/.agents/skills/herdr" "$root/pi-agent/skills/herdr"
  printf 'working Copilot herdr skill\n' > "$root/copilot-home/skills/herdr/SKILL.md"

  set +e
  RUNTIME_TEST_HERDR_SKILL_FAILURE=1 \
    run_installer "$root" "Linux" 0 >"$output" 2>&1
  status=$?
  set -e

  [ "$status" -ne 0 ] || fail "$name unexpectedly succeeded"
  assert_contains "mock herdr skill failure" "$output"
  assert_contains "existing skills were left unchanged" "$output"
  assert_contains "working standalone herdr skill" "$root/home/.agents/skills/herdr/SKILL.md"
  [ -L "$root/pi-agent/skills/herdr" ] ||
    fail "$name removed the legacy Pi skill link before preparing its replacement"
  assert_contains "working Copilot herdr skill" "$root/copilot-home/skills/herdr/SKILL.md"
  assert_count 0 "exec:pi install:$PI_HERDR_SOURCE" "$root/mise.log"
  assert_count 0 "exec:npx skills remove" "$root/mise.log"
}

run_copilot_skill_publish_failure() {
  local name="copilot-skill-publish-failure"
  local root="$tmp/$name"
  local output="$root/install.out"
  local real_mv status

  setup_fixture "$root" "no" "no"
  mkdir -p \
    "$root/home/.agents/skills/herdr" \
    "$root/home/.copilot/skills/herdr" \
    "$root/pi-agent/skills"
  printf 'working standalone herdr skill\n' > "$root/home/.agents/skills/herdr/SKILL.md"
  printf 'working Copilot herdr skill\n' > "$root/home/.copilot/skills/herdr/SKILL.md"
  ln -s "$root/home/.agents/skills/herdr" "$root/pi-agent/skills/herdr"
  real_mv="$(command -v mv)"
  cat > "$root/system-bin/mv" <<EOF
#!/bin/bash
set -euo pipefail
if [[ "\${1:-}" == *"/.herdr-publish."* &&
  "\${2:-}" = "$root/home/.copilot/skills/herdr" ]]; then
  exit 75
fi
exec "$real_mv" "\$@"
EOF
  chmod 755 "$root/system-bin/mv"

  set +e
  RUNTIME_TEST_COPILOT_HOME="$root/home/.copilot" \
    run_installer "$root" "Linux" 0 >"$output" 2>&1
  status=$?
  set -e

  [ "$status" -ne 0 ] || fail "$name unexpectedly succeeded"
  assert_contains "failed to install the prepared Copilot Herdr skill" "$output"
  assert_not_contains "installed Copilot Herdr skill" "$output"
  assert_contains "working Copilot herdr skill" "$root/home/.copilot/skills/herdr/SKILL.md"
  assert_not_exists "$root/home/.agents/skills/herdr"
  [ -L "$root/pi-agent/skills/herdr" ] ||
    fail "$name removed the configured Pi skill link before publication completed"
  assert_count 1 "exec:pi install:$PI_HERDR_SOURCE" "$root/mise.log"
  assert_count 1 "exec:npx skills remove" "$root/mise.log"
  if find "$root/home/.copilot/skills" -maxdepth 1 \
    \( -name '.herdr-skill.*' -o -name '.herdr-publish.*' -o \
      -name '.herdr-backup.*' -o -name '.herdr-previous.*' \) \
    -print -quit |
    grep -q .; then
    fail "$name left a staging or backup directory behind"
  fi
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
  assert_reviewer_profile "$name" "$root/pi-agent"
  assert_no_runtime_markers "$name" "$root"
}

run_mcp_adapter_upgrade_migration() {
  local name="mcp-adapter-upgrade-migration"
  local root="$tmp/$name"
  local log="$root/mise.log"
  local output="$root/install.out"

  setup_fixture "$root" "no" "no"
  mkdir -p "$root/pi-agent"
  cat > "$root/pi-agent/mcp.json" <<'JSON'
{
  "mcpServers": {
    "existing": {
      "command": "existing"
    }
  }
}
JSON
  cat > "$root/pi-agent/mcp-adapter.json" <<'JSON'
{
  "mcpServers": {
    "legacyOnly": {
      "command": "legacy-only"
    },
    "__proto__": {
      "command": "proto-server"
    },
    "playwright": {
      "command": "old-playwright"
    }
  },
  "settings": {
    "mcpFooterStatus": "off"
  }
}
JSON
  printf 'preserved migration backup\n' > "$root/pi-agent/mcp-adapter.json.migrated"
  printf 'preserved numbered migration backup\n' > "$root/pi-agent/mcp-adapter.json.migrated.1"

  if ! run_installer "$root" "Linux" 0 "$MCP_ADAPTER_SOURCE" >"$output" 2>&1; then
    cat "$output" >&2
    fail "$name installer run failed"
  fi

  assert_count 1 "exec:node migrate-mcp-adapter:mcp-adapter.json" "$log"
  assert_count 1 "exec:pi remove:$MCP_ADAPTER_SOURCE" "$log"
  assert_contains "legacy mcp-adapter.json migrated 3 MCP server(s)" "$output"
  assert_contains "legacy MCP adapter key 'settings' is adapter-specific and was not copied" "$output"
  assert_contains "retired legacy mcp-adapter.json -> $root/pi-agent/mcp-adapter.json.migrated.2" "$output"
  assert_contains "removed $MCP_ADAPTER_SOURCE" "$output"
  assert_not_exists "$root/pi-agent/mcp-adapter.json"
  assert_json "$root/pi-agent/mcp-adapter.json.migrated.2" \
    'value.mcpServers.legacyOnly.command === "legacy-only" && Object.hasOwn(value.mcpServers, "__proto__") && value.mcpServers["__proto__"].command === "proto-server" && value.settings.mcpFooterStatus === "off"' \
    "$name did not preserve the legacy adapter config backup"
  grep -Fxq 'preserved migration backup' "$root/pi-agent/mcp-adapter.json.migrated" ||
    fail "$name overwrote the existing legacy MCP backup"
  grep -Fxq 'preserved numbered migration backup' "$root/pi-agent/mcp-adapter.json.migrated.1" ||
    fail "$name overwrote the existing numbered legacy MCP backup"
  assert_json "$root/pi-agent/mcp.json" \
    'value.mcpServers.existing.command === "existing" && value.mcpServers.legacyOnly.command === "legacy-only" && Object.hasOwn(value.mcpServers, "__proto__") && value.mcpServers["__proto__"].command === "proto-server" && value.mcpServers.playwright.command === "npx" && value.mcpServers.playwright.args.join(" ") === "-y @playwright/mcp@latest --browser firefox" && value.mcpServers.context7.command === "npx"' \
    "$name did not merge legacy and shared MCP servers into built-in mcp.json"
  assert_no_runtime_markers "$name" "$root"
}

run_symlink_preserves_local_files() {
  local name="symlink-preserves-local-files"
  local root="$tmp/$name"
  local output="$root/install.out"

  setup_fixture "$root" "no" "no"
  mkdir -p \
    "$root/pi-agent/agents" \
    "$root/pi-agent/extensions/subagent"
  printf 'local reviewer extension\n' > "$root/pi-agent/extensions/reviewer-git.ts"
  printf 'existing reviewer backup\n' > "$root/pi-agent/extensions/reviewer-git.ts.backup"
  printf 'local status extension\n' > "$root/pi-agent/extensions/subagent-status.ts"
  printf 'local reviewer profile\n' > "$root/pi-agent/agents/reviewer.md"
  printf 'local footer config\n' > "$root/pi-agent/catppuccin-footer.json"
  cat > "$root/pi-agent/settings.json" <<'JSON'
{
  "localOnly": true
}
JSON
  cat > "$root/pi-agent/mcp.json" <<'JSON'
{
  "mcpServers": {
    "local": {
      "command": "local"
    }
  }
}
JSON

  if ! run_installer "$root" "Linux" 0 >"$output" 2>&1; then
    cat "$output" >&2
    fail "$name installer run failed"
  fi

  assert_symlink_to \
    "$REPO_ROOT/pi/agent-stack/extensions/reviewer-git.ts" \
    "$root/pi-agent/extensions/reviewer-git.ts"
  assert_symlink_to \
    "$REPO_ROOT/pi/agent-stack/extensions/subagent-status.ts" \
    "$root/pi-agent/extensions/subagent-status.ts"
  assert_symlink_to \
    "$REPO_ROOT/pi/agent-stack/profiles/reviewer.md" \
    "$root/pi-agent/agents/reviewer.md"
  assert_symlink_to \
    "$REPO_ROOT/pi/agent-stack/catppuccin-footer.json" \
    "$root/pi-agent/catppuccin-footer.json"
  grep -Fxq 'existing reviewer backup' \
    "$root/pi-agent/extensions/reviewer-git.ts.backup" ||
    fail "$name overwrote the existing reviewer backup"
  grep -Fxq 'local reviewer extension' \
    "$root/pi-agent/extensions/reviewer-git.ts.backup.1" ||
    fail "$name did not choose a unique backup for the local reviewer extension"
  grep -Fxq 'local status extension' \
    "$root/pi-agent/extensions/subagent-status.ts.backup" ||
    fail "$name did not back up the local status extension"
  grep -Fxq 'local reviewer profile' \
    "$root/pi-agent/agents/reviewer.md.backup" ||
    fail "$name did not back up the local reviewer profile"
  grep -Fxq 'local footer config' \
    "$root/pi-agent/catppuccin-footer.json.backup" ||
    fail "$name did not back up the local footer config"
  [ ! -L "$root/pi-agent/settings.json" ] ||
    fail "$name symlinked settings.json"
  [ ! -L "$root/pi-agent/mcp.json" ] ||
    fail "$name symlinked mcp.json"
  assert_json "$root/pi-agent/settings.json" \
    'value.localOnly === true && value.quietStartup === "header"' \
    "$name did not preserve local settings while merging shared settings"
  assert_json "$root/pi-agent/mcp.json" \
    'value.mcpServers.local.command === "local" && value.mcpServers.playwright.command === "npx"' \
    "$name did not preserve local MCP servers while merging shared MCP config"
  assert_contains "moved existing reviewer-git.ts aside -> $root/pi-agent/extensions/reviewer-git.ts.backup.1" "$output"
  assert_contains "moved existing subagent-status.ts aside -> $root/pi-agent/extensions/subagent-status.ts.backup" "$output"
  assert_contains "moved existing reviewer.md aside -> $root/pi-agent/agents/reviewer.md.backup" "$output"
  assert_contains "moved existing catppuccin-footer.json aside -> $root/pi-agent/catppuccin-footer.json.backup" "$output"
  assert_no_runtime_markers "$name" "$root"
}

run_success_scenario "qualifying-system-runtimes" "yes" "Linux" "no"
run_success_scenario "absent-system-runtimes" "no" "Linux" "no"
run_success_scenario "darwin-with-lockf" "no" "Darwin" "yes"
run_darwin_with_brew_installs_backlog_md_and_sync
run_darwin_with_existing_backlog_tools_skips_brew
run_darwin_with_failing_brew_warns_and_continues
run_darwin_no_lockf
run_pi_list_failure
run_invalid_settings_json
run_herdr_skill_generation_failure
run_copilot_skill_publish_failure

run_special_agent_dir() {
  local name="special-agent-dir"
  local root="$tmp/$name"
  local output="$root/install.out"
  local agent_dir="$root/pi&agent|x,y\\z"

  setup_fixture "$root" "no" "no"
  if ! RUNTIME_TEST_PI_AGENT_DIR="$agent_dir" \
    run_installer "$root" "Linux" 0 >"$output" 2>&1; then
    cat "$output" >&2
    fail "$name installer run failed"
  fi
  assert_reviewer_profile "$name" "$agent_dir"
}

run_special_agent_dir
run_success_scenario "filtered-user-package" "no" "Linux" "no" " (filtered)"
run_migration "legacy-maxedapps-migration" "$LEGACY_SOURCE"
run_migration "pinned-version-migration" "npm:pi-subagents@0.73.1"
run_mcp_adapter_upgrade_migration
run_symlink_preserves_local_files

printf 'installer mise runtime tests passed\n'
