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
MCP_CONFIG_PATH="$PI_AGENT_DIR/mcp.json"
LEGACY_MCP_ADAPTER_CONFIG_PATH="$PI_AGENT_DIR/mcp-adapter.json"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
PACKAGES_FILE="$DIR/packages.txt"
SETTINGS_FILE="$DIR/settings.json"
SUBAGENT_CONFIG_FILE="$DIR/subagent-config.json"
MCP_CONFIG_FILE="$DIR/mcp.json"
FOOTER_FILE="$DIR/catppuccin-footer.json"
# nicobailon/pi-subagents, deliberately unpinned: Pi and Herdr float at latest
# through mise, so the extension tracks latest too and is updated on every run.
SUBAGENTS_PACKAGE="pi-subagents"
SUBAGENTS_SOURCE="npm:$SUBAGENTS_PACKAGE"
MCP_ADAPTER_SOURCE="npm:pi-mcp-adapter"
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

install_backlog_cli() {
  if ! is_mac || ! has brew; then
    return 0
  fi

  if has backlog; then
    ok "backlog CLI is already installed"
    return 0
  fi

  log "Installing Backlog.md CLI"
  if HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_NO_INSTALL_CLEANUP=1 \
    HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 \
    brew install backlog-md; then
    ok "installed backlog-md"
  else
    warn "failed to install backlog-md; continuing without the backlog CLI"
  fi
}

install_backlog_sync() {
  if ! is_mac || ! has brew; then
    return 0
  fi

  if has backlog-sync; then
    ok "backlog-sync is already installed"
    return 0
  fi

  log "Installing backlog-sync"
  if HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_NO_INSTALL_CLEANUP=1 \
    HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 \
    brew install djensenius/tap/backlog-sync; then
    ok "installed backlog-sync"
  else
    warn "failed to install backlog-sync; continuing without backlog-sync"
  fi
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

backup_path_for() {
  local dst="$1" backup_path

  backup_path="$dst.backup"
  if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
    backup_path="$dst.backup.$$"
  fi
  printf '%s\n' "$backup_path"
}

link_file() {
  local src="$1" dst="$2" backup_path

  if [ -L "$dst" ] && [ "$dst" -ef "$src" ]; then
    ok "$(basename "$dst") is linked"
    return
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -f "$dst" ] && [ ! -L "$dst" ] && cmp -s "$src" "$dst"; then
      rm -f "$dst"
    else
      backup_path="$(backup_path_for "$dst")"
      if ! mv "$dst" "$backup_path"; then
        die "failed to back up existing $(basename "$dst")"
      fi
      warn "moved existing $(basename "$dst") aside -> $backup_path"
    fi
  fi

  if ! ln -s "$src" "$dst"; then
    die "failed to link $(basename "$dst")"
  fi
  ok "linked $(basename "$dst") -> $dst"
}

merge_json_file() {
  local src="$1" dst="$2" label="$3" result

  if ! result="$(mise_exec node "$DIR/bin/merge-json.mjs" "$dst" "$src")"; then
    die "failed to merge $label"
  fi
  ok "$label $result"
}

migrate_legacy_mcp_adapter_config() {
  local backup_path result

  if [ ! -e "$LEGACY_MCP_ADAPTER_CONFIG_PATH" ] &&
    [ ! -L "$LEGACY_MCP_ADAPTER_CONFIG_PATH" ]; then
    return 0
  fi

  log "Migrating legacy MCP adapter config"
  if [ -f "$LEGACY_MCP_ADAPTER_CONFIG_PATH" ] &&
    [ ! -L "$LEGACY_MCP_ADAPTER_CONFIG_PATH" ]; then
    if ! result="$(mise_exec node "$DIR/bin/migrate-mcp-adapter.mjs" "$LEGACY_MCP_ADAPTER_CONFIG_PATH" "$MCP_CONFIG_PATH")"; then
      die "failed to migrate legacy MCP adapter config"
    fi
    ok "legacy mcp-adapter.json $result"
  else
    warn "legacy mcp-adapter.json is not a regular file; moving it aside without migration"
  fi

  backup_path="$LEGACY_MCP_ADAPTER_CONFIG_PATH.migrated"
  if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
    backup_path="$LEGACY_MCP_ADAPTER_CONFIG_PATH.migrated.$$"
  fi
  if ! mv "$LEGACY_MCP_ADAPTER_CONFIG_PATH" "$backup_path"; then
    die "failed to retire legacy MCP adapter config"
  fi
  ok "retired legacy mcp-adapter.json -> $backup_path"
}

prepare_copilot_herdr_skill() {
  local skills_dir="${COPILOT_HOME:-$HOME/.copilot}/skills"
  local generated_skill

  mkdir -p "$skills_dir" || return 1
  if ! generated_skill="$(mktemp "$skills_dir/.herdr-skill.XXXXXX")"; then
    return 1
  fi
  if ! mise_exec herdr --skill >"$generated_skill"; then
    rm -f "$generated_skill"
    return 1
  fi
  if [ "$(head -n1 "$generated_skill")" != "---" ] ||
    ! grep -Fxq "name: herdr" "$generated_skill"; then
    rm -f "$generated_skill"
    return 1
  fi
  if ! chmod 644 "$generated_skill"; then
    rm -f "$generated_skill"
    return 1
  fi
  printf '%s\n' "$generated_skill"
}

preserve_copilot_herdr_skill() {
  local skills_dir="${COPILOT_HOME:-$HOME/.copilot}/skills"
  local skill_dir="$skills_dir/herdr"
  local canonical_dir="$HOME/.agents/skills/herdr"
  local source_dir="" preserved_dir

  if [ -f "$skill_dir/SKILL.md" ]; then
    source_dir="$skill_dir"
  elif [ -f "$canonical_dir/SKILL.md" ]; then
    source_dir="$canonical_dir"
  else
    return 0
  fi

  mkdir -p "$skills_dir" || return 1
  if ! preserved_dir="$(mktemp -d "$skills_dir/.herdr-previous.XXXXXX")"; then
    return 1
  fi
  if ! cp -R -L "$source_dir/." "$preserved_dir/"; then
    rm -rf -- "$preserved_dir" || warn "failed to clean incomplete Herdr skill backup $preserved_dir"
    return 1
  fi
  if [ ! -f "$preserved_dir/SKILL.md" ]; then
    rm -rf -- "$preserved_dir" || warn "failed to clean invalid Herdr skill backup $preserved_dir"
    return 1
  fi
  printf '%s\n' "$preserved_dir"
}

publish_copilot_herdr_skill() {
  local generated_skill="$1"
  local preserved_skill="${2:-}"
  local skills_dir="${COPILOT_HOME:-$HOME/.copilot}/skills"
  local skill_dir="$skills_dir/herdr"
  local staged_dir backup_dir=""
  local restored=false

  mkdir -p "$skills_dir" || return 1
  if ! staged_dir="$(mktemp -d "$skills_dir/.herdr-publish.XXXXXX")"; then
    return 1
  fi
  if ! mv "$generated_skill" "$staged_dir/SKILL.md"; then
    rmdir "$staged_dir" || warn "failed to clean unused Herdr skill staging directory $staged_dir"
    return 1
  fi

  if [ -e "$skill_dir" ] || [ -L "$skill_dir" ]; then
    if ! backup_dir="$(mktemp -d "$skills_dir/.herdr-backup.XXXXXX")"; then
      rm -rf -- "$staged_dir" || warn "failed to clean Herdr skill staging directory $staged_dir"
      return 1
    fi
    if ! rmdir "$backup_dir"; then
      rm -rf -- "$staged_dir" || warn "failed to clean Herdr skill staging directory $staged_dir"
      rm -rf -- "$backup_dir" || warn "failed to clean unused Herdr skill backup directory $backup_dir"
      return 1
    fi
    if ! mv "$skill_dir" "$backup_dir"; then
      rm -rf -- "$staged_dir" || warn "failed to clean Herdr skill staging directory $staged_dir"
      return 1
    fi
  fi

  if ! mv "$staged_dir" "$skill_dir"; then
    if [ -n "$backup_dir" ] && mv "$backup_dir" "$skill_dir"; then
      restored=true
    elif [ -n "$preserved_skill" ] && mv "$preserved_skill" "$skill_dir"; then
      restored=true
      preserved_skill=""
    fi
    if ! $restored; then
      warn "failed to restore the previous Copilot Herdr skill; preserved copies remain under $skills_dir"
    fi
    rm -rf -- "$staged_dir" || warn "failed to clean Herdr skill staging directory $staged_dir"
    if $restored && [ -n "$preserved_skill" ]; then
      rm -rf -- "$preserved_skill" || warn "failed to clean preserved Herdr skill backup $preserved_skill"
    fi
    if [ -n "$backup_dir" ] && { [ -e "$backup_dir" ] || [ -L "$backup_dir" ]; }; then
      warn "a previous Copilot Herdr skill backup remains at $backup_dir"
    fi
    return 1
  fi

  if [ -n "$backup_dir" ] && ! rm -rf -- "$backup_dir"; then
    warn "installed the Copilot Herdr skill but could not remove backup $backup_dir"
  fi
  if [ -n "$preserved_skill" ] && ! rm -rf -- "$preserved_skill"; then
    warn "installed the Copilot Herdr skill but could not remove preserved backup $preserved_skill"
  fi
  ok "installed Copilot Herdr skill -> $skill_dir/SKILL.md"
}

main() {
  local node_version pi_version herdr_version packages sources managed_sources
  local current_subagents stale_sources stale_source profile package_source extension
  local generated_copilot_skill="" preserved_copilot_skill="" legacy_pi_skill
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
  stale_sources="$(grep -E "^npm:$SUBAGENTS_PACKAGE@|$LEGACY_SOURCE_PATTERN|^$MCP_ADAPTER_SOURCE(@|$)" <<<"$sources" || true)"

  log "Installing shared Pi configuration"
  merge_json_file "$SETTINGS_FILE" "$PI_AGENT_DIR/settings.json" "settings.json"
  merge_json_file "$SUBAGENT_CONFIG_FILE" "$SUBAGENT_CONFIG_PATH" "subagent config.json"
  migrate_legacy_mcp_adapter_config
  merge_json_file "$MCP_CONFIG_FILE" "$MCP_CONFIG_PATH" "mcp.json"
  link_file "$FOOTER_FILE" "$PI_AGENT_DIR/catppuccin-footer.json"

  log "Installing repository-managed Pi packages"
  while IFS= read -r package_source; do
    [ "$package_source" = "$PI_HERDR_SOURCE" ] && continue
    if has_package_source "$package_source" "$sources"; then
      ok "$package_source is already installed"
    else
      if ! mise_exec pi install "$package_source"; then
        [ -z "$generated_copilot_skill" ] || rm -f "$generated_copilot_skill"
        die "failed to install $package_source"
      fi
      ok "installed $package_source"
    fi
  done <<<"$managed_sources"

  if $manages_pi_herdr &&
    [ "${SKIP_HERDR_SKILL:-0}" != "1" ] &&
    has copilot; then
    log "Preparing the Copilot Herdr skill"
    if ! generated_copilot_skill="$(prepare_copilot_herdr_skill)"; then
      die "failed to generate valid Copilot Herdr guidance; existing skills were left unchanged"
    fi
    if ! preserved_copilot_skill="$(preserve_copilot_herdr_skill)"; then
      rm -f "$generated_copilot_skill"
      die "failed to preserve the existing Copilot Herdr skill"
    fi
  fi

  if $manages_pi_herdr; then
    if has_package_source "$PI_HERDR_SOURCE" "$sources"; then
      ok "$PI_HERDR_SOURCE is already installed"
    else
      if ! mise_exec pi install "$PI_HERDR_SOURCE"; then
        [ -z "$generated_copilot_skill" ] || rm -f "$generated_copilot_skill"
        [ -z "$preserved_copilot_skill" ] || rm -rf -- "$preserved_copilot_skill"
        die "failed to install $PI_HERDR_SOURCE"
      fi
      ok "installed $PI_HERDR_SOURCE"
    fi
  fi

  if [ "${SKIP_HERDR_SKILL:-0}" != "1" ]; then
    if $manages_pi_herdr; then
      log "Removing superseded standalone Herdr skill"
      if ! mise_exec npx -y skills remove herdr -g -y; then
        if [ -n "$generated_copilot_skill" ]; then
          if ! publish_copilot_herdr_skill "$generated_copilot_skill" "$preserved_copilot_skill"; then
            rm -f "$generated_copilot_skill"
            die "failed to remove the standalone global Herdr skill and failed to restore Copilot guidance"
          fi
          generated_copilot_skill=""
          preserved_copilot_skill=""
        fi
        die "failed to remove the standalone global Herdr skill"
      fi
      ok "removed standalone global Herdr skill; @narumitw/pi-herdr provides Pi's Herdr skill"
      if [ -n "$generated_copilot_skill" ]; then
        if ! publish_copilot_herdr_skill "$generated_copilot_skill" "$preserved_copilot_skill"; then
          rm -f "$generated_copilot_skill"
          die "failed to install the prepared Copilot Herdr skill"
        fi
        generated_copilot_skill=""
        preserved_copilot_skill=""
      fi

      legacy_pi_skill="$PI_AGENT_DIR/skills/herdr"
      if [ -e "$legacy_pi_skill" ] || [ -L "$legacy_pi_skill" ]; then
        if ! rm -rf -- "$legacy_pi_skill"; then
          die "failed to remove the legacy Pi Herdr skill link"
        fi
        ok "removed legacy Pi Herdr skill link"
      else
        ok "legacy Pi Herdr skill link is absent"
      fi
    else
      log "Installing the official Herdr skill"
      mise_exec npx -y skills add herdrdev/herdr --skill herdr --agent pi github-copilot -g -y
    fi
  fi

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

  log "Installing repository-owned Pi extensions"
  mkdir -p "$PI_AGENT_DIR/extensions"
  for extension in "$DIR"/extensions/*.ts; do
    link_file "$extension" "$PI_AGENT_DIR/extensions/$(basename "$extension")"
  done

  if [ -n "$stale_sources" ]; then
    log "Removing superseded Pi packages"
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

  log "Installing Pi subagent profiles"
  # Profiles reference extensions relative to the agent file
  # (../extensions/...), which pi-subagents resolves after splitting its
  # comma-separated lists, so any PI_CODING_AGENT_DIR works unmodified.
  mkdir -p "$AGENTS_DIR"
  for profile in "$DIR"/profiles/*.md; do
    link_file "$profile" "$AGENTS_DIR/$(basename "$profile")"
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

  install_backlog_cli
  install_backlog_sync

  cat <<EOF

Agent stack installed.

Subagents extension (latest):
  $SUBAGENTS_SOURCE

Enable the coordinator workflow in a repository (land this setup through a PR,
because Copilot reads instructions from the base branch):
  # On non-Homebrew systems, install the Backlog.md CLI and backlog-sync first:
  # npm i -g backlog.md
  # Install backlog-sync from https://github.com/djensenius/backlog-sync
  cp "$DIR/templates/AGENTS.md" ./AGENTS.md
  backlog init --backlog-dir .backlog
  backlog config set autoCommit true
  backlog config set checkActiveBranches true
  backlog agents --update-instructions
  mkdir -p .github/instructions
  cp "$DIR/templates/backlog.instructions.md" .github/instructions/
  # Add this two-line Backlog section to the repo's .github/copilot-instructions.md:
  # ## Backlog.md files
  # Copilot code review must not review or comment on Backlog.md task files; \`.github/instructions/backlog.instructions.md\` owns the path rule.
  # Then enable automatic Copilot code review and a ruleset requiring CI before merge.

Smoke test from Pi (ideally in a Herdr pane):
  Use a scout subagent to map how this project is structured.
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
