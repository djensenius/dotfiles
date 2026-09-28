#!/usr/bin/env bash
# Installs the Pi + Herdr multi-agent coordination stack.
#
# Re-run after pulling dotfiles changes to refresh profiles and wrappers.
#
# Env:
#   SKIP_HERDR_SKILL=1          Skip the global Herdr skill installation.
#   PI_CODING_AGENT_DIR=path    Override Pi's agent directory.
#   BIN_DIR=path                Override the wrapper installation directory.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
AGENTS_DIR="$PI_AGENT_DIR/agents"
LEGACY_PROFILE_DIR="$PI_AGENT_DIR/herdr-subagents/agents"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
# nicobailon/pi-subagents, deliberately unpinned: Pi and Herdr float at latest
# through mise, so the extension tracks latest too and is updated on every run.
SUBAGENTS_PACKAGE="pi-subagents"
SUBAGENTS_SOURCE="npm:$SUBAGENTS_PACKAGE"
# The previous stack used maxedapps/pi-subagents-herdr, which is incompatible
# with Herdr 0.9.1 (agent.start requires kind + pane). It is removed on upgrade.
LEGACY_SOURCE_PATTERN='^(npm:@maxedapps/pi-subagents-herdr|git:github\.com/maxedapps/pi-subagents-herdr)(@|$)'
MIN_GIT="2.45.0"
MIN_NODE="22.19.0"
GIT_VERSION=""
MISE_BIN=""
PROFILE_TMP=""

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m OK\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m XX\033[0m %s\n' "$*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }
is_mac() { [ "$(uname -s)" = "Darwin" ]; }

# Prints one installed package source per line from `pi list` output.
package_sources() {
  sed -nE 's/^[[:space:]]*((npm|git):[^[:space:]]+)[[:space:]]*$/\1/p' <<<"$1"
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

main() {
  local node_version pi_version herdr_version packages sources
  local current_subagents stale_sources stale_source profile

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

  log "Inspecting installed Pi packages"
  if ! packages="$(mise_exec pi list)"; then
    die "failed to inspect installed Pi packages"
  fi
  sources="$(package_sources "$packages")"
  current_subagents="$(grep -Fx "$SUBAGENTS_SOURCE" <<<"$sources" || true)"
  # Version-pinned pi-subagents entries and the legacy maxedapps extension are
  # replaced by the unpinned package.
  stale_sources="$(grep -E "^npm:$SUBAGENTS_PACKAGE@|$LEGACY_SOURCE_PATTERN" <<<"$sources" || true)"

  log "Installing repository-owned Pi extensions"
  mkdir -p "$PI_AGENT_DIR/extensions"
  sync_file "$DIR/extensions/reviewer-git.ts" "$PI_AGENT_DIR/extensions/reviewer-git.ts"

  log "Installing Herdr agent integrations"
  mise_exec herdr integration install pi
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
    log "Installing the official Herdr skill"
    mise_exec npx -y skills add herdrdev/herdr --skill herdr --agent pi github-copilot -g -y
  fi

  log "Installing Pi subagent profiles"
  mkdir -p "$AGENTS_DIR"
  PROFILE_TMP="$(mktemp -d)"
  trap 'rm -rf "$PROFILE_TMP"' EXIT
  for profile in "$DIR"/profiles/*.md; do
    sed "s|@REVIEWER_GIT_EXTENSION@|$PI_AGENT_DIR/extensions/reviewer-git.ts|g" \
      "$profile" > "$PROFILE_TMP/$(basename "$profile")"
    sync_file "$PROFILE_TMP/$(basename "$profile")" "$AGENTS_DIR/$(basename "$profile")"
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

  # herdr/config.toml launches panes with the herdr-fish wrapper; without it
  # Herdr cannot create a workspace. The dotfiles installers own this link.
  if ! has herdr-fish && [ ! -x "$BIN_DIR/herdr-fish" ]; then
    warn "herdr-fish is not on PATH; Herdr panes will fail to start (see README: Special setup for Herdr)"
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
