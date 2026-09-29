#!/usr/bin/env bash
# Installs the Pi + Herdr multi-agent coordination stack.
#
# Re-run after pulling dotfiles changes to refresh profiles and wrappers.
#
# Env:
#   SKIP_HERDR_SKILL=1          Skip Herdr skill installation and migration.
#   PI_CODING_AGENT_DIR=path    Override Pi's agent directory.
#   BIN_DIR=path                Override the wrapper installation directory.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
AGENTS_DIR="$PI_AGENT_DIR/agents"
LEGACY_PROFILE_DIR="$PI_AGENT_DIR/herdr-subagents/agents"
SUBAGENT_CONFIG_DIR="$PI_AGENT_DIR/extensions/subagent"
SUBAGENT_CONFIG_PATH="$SUBAGENT_CONFIG_DIR/config.json"
MCP_ADAPTER_CONFIG_PATH="$PI_AGENT_DIR/mcp-adapter.json"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
PACKAGES_FILE="$DIR/packages.txt"
SETTINGS_FILE="$DIR/settings.json"
SUBAGENT_CONFIG_FILE="$DIR/subagent-config.json"
MCP_ADAPTER_CONFIG_FILE="$DIR/mcp-adapter.json"
FOOTER_FILE="$DIR/catppuccin-footer.json"
# nicobailon/pi-subagents, deliberately unpinned: Pi and Herdr float at latest
# through mise, so the extension tracks latest too and is updated on every run.
SUBAGENTS_PACKAGE="pi-subagents"
SUBAGENTS_SOURCE="npm:$SUBAGENTS_PACKAGE"
PI_HERDR_SOURCE="npm:@narumitw/pi-herdr"
# The previous stack used maxedapps/pi-subagents-herdr, which is incompatible
# with Herdr 0.9.1 (agent.start requires kind + pane). It is removed on upgrade.
LEGACY_SOURCE_PATTERN='^(npm:@maxedapps/pi-subagents-herdr|git:github\.com/maxedapps/pi-subagents-herdr)(@|$)'
MIN_GIT="2.45.0"
MIN_NODE="22.19.0"
GIT_VERSION=""
MISE_BIN=""

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m OK\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m XX\033[0m %s\n' "$*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }
is_mac() { [ "$(uname -s)" = "Darwin" ]; }

# Prints one user-scope package source per line from `pi list` output. Only the
# "User packages:" section is read (the installer manages global packages), ANSI
# styling is stripped, and display suffixes such as " (filtered)" are dropped.
package_sources() {
  awk '
    { gsub(/\033\[[0-9;]*m/, "") }
    /^User packages:/ { user = 1; next }
    /^[^[:space:]]/ { user = 0; next }
    user && /^  [^[:space:]]/ { print $1 }
  ' <<<"$1"
}

managed_package_sources() {
  awk '
    /^[[:space:]]*#/ { next }
    {
      sub(/[[:space:]]+#.*$/, "")
      sub(/^[[:space:]]+/, "")
      sub(/[[:space:]]+$/, "")
    }
    $0 != "" { print }
  ' "$PACKAGES_FILE"
}

# True when $2 (pi list sources, one per line) already has $1, either
# unpinned or pinned to a version (npm:foo or npm:foo@1.2.3).
has_package_source() {
  local wanted="$1" source
  while IFS= read -r source; do
    if [ "$source" = "$wanted" ] || [[ "$source" == "$wanted@"* ]]; then
      return 0
    fi
  done <<<"$2"
  return 1
}

mise_exec() {
  "$MISE_BIN" -C "$REPO_ROOT" exec -- "$@"
}

require_git_version() {
  local output pattern major minor patch

  has git || die "Git >= $MIN_GIT is required. Install or upgrade Git with Homebrew (brew install git) on macOS or your OS package manager, then ensure the upgraded binary is first on PATH."
  if ! output="$(git --version 2>&1)"; then
    die "Git >= $MIN_GIT is required, but git --version failed. Upgrade Git with Homebrew (brew install git) on macOS or your OS package manager, then ensure the upgraded binary is first on PATH."
  fi

  pattern='^git[[:space:]]+version[[:space:]]+([0-9]+)\.([0-9]+)\.([0-9]+)(\.windows\.[0-9]+)?([[:space:]]+\(Apple[[:space:]]Git-[^)]+\))?$'
  if [[ "$output" == *$'\n'* || "$output" == *$'\r'* || ! "$output" =~ $pattern ]]; then
    die "could not parse git --version output '$output'. Git >= $MIN_GIT is required; upgrade Git with Homebrew (brew install git) on macOS or your OS package manager, then ensure the upgraded binary is first on PATH."
  fi

  major=$((10#${BASH_REMATCH[1]}))
  minor=$((10#${BASH_REMATCH[2]}))
  patch=$((10#${BASH_REMATCH[3]}))

  if (( major < 2 || (major == 2 && minor < 45) )); then
    die "Git >= $MIN_GIT is required (found $major.$minor.$patch). Upgrade Git with Homebrew (brew install git) on macOS or your OS package manager, then ensure the upgraded binary is first on PATH."
  fi

  GIT_VERSION="$major.$minor.$patch"
}

node_ok() {
  mise_exec node -e '
    const actual = process.versions.node.split(".").map(Number);
    const minimum = process.argv[1].split(".").map(Number);
    for (let index = 0; index < 3; index++) {
      if (actual[index] > minimum[index]) process.exit(0);
      if (actual[index] < minimum[index]) process.exit(1);
    }
  ' "$MIN_NODE"
}

sync_file() {
  local src="$1" dst="$2" mode="${3:-644}"
  if [ -f "$dst" ] && [ ! -L "$dst" ] && cmp -s "$src" "$dst"; then
    chmod "$mode" "$dst"
    ok "$(basename "$dst") is up to date"
    return
  fi

  rm -f "$dst"
  install -m "$mode" "$src" "$dst"
  ok "installed $(basename "$dst") -> $dst"
}

merge_json_file() {
  local src="$1" dst="$2" label="$3" result

  if ! result="$(mise_exec node "$DIR/bin/merge-json.mjs" "$dst" "$src")"; then
    die "failed to merge $label"
  fi
  ok "$label $result"
}

prepare_copilot_herdr_skill() {
  local skills_dir="${COPILOT_HOME:-$HOME/.copilot}/skills"
  local generated_skill

  mkdir -p "$skills_dir"
  generated_skill="$(mktemp "$skills_dir/.herdr-skill.XXXXXX")"
  if ! mise_exec herdr --skill >"$generated_skill"; then
    rm -f "$generated_skill"
    return 1
  fi
  if [ "$(head -n1 "$generated_skill")" != "---" ] ||
    ! grep -Fxq "name: herdr" "$generated_skill"; then
    rm -f "$generated_skill"
    return 1
  fi
  chmod 644 "$generated_skill"
  printf '%s\n' "$generated_skill"
}

publish_copilot_herdr_skill() {
  local generated_skill="$1"
  local skill_dir="${COPILOT_HOME:-$HOME/.copilot}/skills/herdr"

  if [ -e "$skill_dir" ] || [ -L "$skill_dir" ]; then
    rm -rf -- "$skill_dir"
  fi
  mkdir -p "$skill_dir"
  mv -f "$generated_skill" "$skill_dir/SKILL.md"
  ok "installed Copilot Herdr skill -> $skill_dir/SKILL.md"
}

main() {
  local node_version pi_version herdr_version packages sources managed_sources
  local current_subagents stale_sources stale_source profile package_source extension
  local generated_copilot_skill="" legacy_pi_skill
  local manages_pi_herdr=false

  log "Checking prerequisites"
  require_git_version
  has curl || die "curl is required"
  has mise || die "mise is required; install it first from https://mise.jdx.dev"
  MISE_BIN="$(command -v mise)"
  if is_mac; then
    has lockf || die "macOS lockf is required by xbuild"
  fi

  log "Installing mise-managed Node, Pi, and Herdr"
  "$MISE_BIN" -C "$REPO_ROOT" trust "$REPO_ROOT/mise/config.toml" >/dev/null
  "$MISE_BIN" -C "$REPO_ROOT" install node npm pi herdr
  "$MISE_BIN" -C "$REPO_ROOT" reshim
  export PATH="$HOME/.local/share/mise/shims:$PATH"
  hash -r

  node_version="$(mise_exec node -p 'process.versions.node')" ||
    die "mise-managed node is unavailable after installation"
  node_ok || die "mise-managed node >= $MIN_NODE is required (current: $node_version)"
  mise_exec npx --version >/dev/null || die "mise-managed npx is unavailable after installation"
  pi_version="$(mise_exec pi --version | head -n1)" ||
    die "mise-managed pi is unavailable after installation"
  herdr_version="$(mise_exec herdr --version | head -n1)" ||
    die "mise-managed herdr is unavailable after installation"
  ok "git $GIT_VERSION, node v$node_version, pi $pi_version, $herdr_version"

  [ -r "$PACKAGES_FILE" ] || die "missing package list: $PACKAGES_FILE"
  managed_sources="$(managed_package_sources)"
  if has_package_source "$PI_HERDR_SOURCE" "$managed_sources"; then
    manages_pi_herdr=true
  fi

  log "Inspecting installed Pi packages"
  if ! packages="$(mise_exec pi list)"; then
    die "failed to inspect installed Pi packages"
  fi
  sources="$(package_sources "$packages")"
  current_subagents="$(grep -Fx "$SUBAGENTS_SOURCE" <<<"$sources" || true)"
  # Version-pinned pi-subagents entries and the legacy maxedapps extension are
  # replaced by the unpinned package.
  stale_sources="$(grep -E "^npm:$SUBAGENTS_PACKAGE@|$LEGACY_SOURCE_PATTERN" <<<"$sources" || true)"

  log "Installing shared Pi configuration"
  merge_json_file "$SETTINGS_FILE" "$PI_AGENT_DIR/settings.json" "settings.json"
  merge_json_file "$SUBAGENT_CONFIG_FILE" "$SUBAGENT_CONFIG_PATH" "subagent config.json"
  merge_json_file "$MCP_ADAPTER_CONFIG_FILE" "$MCP_ADAPTER_CONFIG_PATH" "mcp-adapter.json"
  sync_file "$FOOTER_FILE" "$PI_AGENT_DIR/catppuccin-footer.json"

  log "Installing repository-managed Pi packages"
  while IFS= read -r package_source; do
    if has_package_source "$package_source" "$sources"; then
      ok "$package_source is already installed"
    else
      mise_exec pi install "$package_source"
      ok "installed $package_source"
    fi
  done <<<"$managed_sources"

  log "Installing repository-owned Pi extensions"
  mkdir -p "$PI_AGENT_DIR/extensions"
  for extension in "$DIR"/extensions/*.ts; do
    sync_file "$extension" "$PI_AGENT_DIR/extensions/$(basename "$extension")"
  done

  log "Installing Herdr agent integrations"
  if $manages_pi_herdr; then
    if [ -f "$PI_AGENT_DIR/extensions/herdr-agent-state.ts" ]; then
      rm -f "$PI_AGENT_DIR/extensions/herdr-agent-state.ts"
      ok "removed standalone Herdr Pi lifecycle integration"
    else
      ok "standalone Herdr Pi lifecycle integration is absent"
    fi
  else
    mise_exec herdr integration install pi
  fi
  if has copilot; then
    mkdir -p "${COPILOT_HOME:-$HOME/.copilot}"
    mise_exec herdr integration install copilot
  else
    warn "copilot CLI is not installed; skipping its Herdr integration"
  fi

  if [ -n "$stale_sources" ]; then
    log "Removing superseded subagents packages"
    while IFS= read -r stale_source; do
      mise_exec pi remove "$stale_source"
      ok "removed $stale_source"
    done <<<"$stale_sources"
  fi

  log "Installing the latest Pi subagents extension"
  if [ -n "$current_subagents" ]; then
    mise_exec pi update --extension "$SUBAGENTS_SOURCE"
    ok "updated $SUBAGENTS_SOURCE"
  else
    mise_exec pi install "$SUBAGENTS_SOURCE"
    ok "installed $SUBAGENTS_SOURCE"
  fi

  if [ "${SKIP_HERDR_SKILL:-0}" != "1" ]; then
    if $manages_pi_herdr; then
      if has copilot; then
        log "Preparing the Copilot Herdr skill"
        if ! generated_copilot_skill="$(prepare_copilot_herdr_skill)"; then
          die "failed to generate valid Copilot Herdr guidance; existing skills were left unchanged"
        fi
      fi

      log "Removing superseded standalone Herdr skill"
      legacy_pi_skill="$PI_AGENT_DIR/skills/herdr"
      if [ -e "$legacy_pi_skill" ] || [ -L "$legacy_pi_skill" ]; then
        if ! rm -rf -- "$legacy_pi_skill"; then
          [ -z "$generated_copilot_skill" ] || rm -f "$generated_copilot_skill"
          die "failed to remove the legacy Pi Herdr skill link"
        fi
        ok "removed legacy Pi Herdr skill link"
      else
        ok "legacy Pi Herdr skill link is absent"
      fi
      if ! mise_exec npx -y skills remove herdr -g -y; then
        if [ -n "$generated_copilot_skill" ]; then
          if ! publish_copilot_herdr_skill "$generated_copilot_skill"; then
            rm -f "$generated_copilot_skill"
            die "failed to remove the standalone global Herdr skill and failed to restore Copilot guidance"
          fi
          generated_copilot_skill=""
        fi
        die "failed to remove the standalone global Herdr skill"
      fi
      ok "removed standalone global Herdr skill; @narumitw/pi-herdr provides Pi's Herdr skill"
      if [ -n "$generated_copilot_skill" ]; then
        if ! publish_copilot_herdr_skill "$generated_copilot_skill"; then
          rm -f "$generated_copilot_skill"
          die "failed to install the prepared Copilot Herdr skill"
        fi
        generated_copilot_skill=""
      fi
    else
      log "Installing the official Herdr skill"
      mise_exec npx -y skills add herdrdev/herdr --skill herdr --agent pi github-copilot -g -y
    fi
  fi

  log "Installing Pi subagent profiles"
  # Profiles reference extensions relative to the agent file
  # (../extensions/...), which pi-subagents resolves after splitting its
  # comma-separated lists, so any PI_CODING_AGENT_DIR works unmodified.
  mkdir -p "$AGENTS_DIR"
  for profile in "$DIR"/profiles/*.md; do
    sync_file "$profile" "$AGENTS_DIR/$(basename "$profile")"
  done
  for profile in reviewer.md worker.md; do
    if [ -f "$LEGACY_PROFILE_DIR/$profile" ]; then
      rm -f "$LEGACY_PROFILE_DIR/$profile"
      ok "removed legacy profile $LEGACY_PROFILE_DIR/$profile"
    fi
  done
  rmdir "$LEGACY_PROFILE_DIR" "$PI_AGENT_DIR/herdr-subagents" 2>/dev/null || true

  if is_mac; then
    log "Installing xbuild"
    mkdir -p "$BIN_DIR"
    sync_file "$DIR/bin/xbuild" "$BIN_DIR/xbuild" 755
    case ":$PATH:" in
      *":$BIN_DIR:"*) ;;
      *) warn "$BIN_DIR is not on PATH" ;;
    esac
    has xcodebuild || warn "xcodebuild is unavailable; install Xcode before using xbuild"
  fi

  cat <<EOF

Agent stack installed.

Subagents extension (latest):
  $SUBAGENTS_SOURCE

Enable the coordinator workflow in a repository:
  cp "$DIR/templates/AGENTS.md" ./AGENTS.md

Smoke test from Pi (ideally in a Herdr pane):
  Use a scout subagent to map how this project is structured.
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
