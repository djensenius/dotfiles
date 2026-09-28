#!/usr/bin/env bash
# Installs the Pi + Herdr multi-agent coordination stack.
#
# Re-run after pulling dotfiles changes to refresh profiles and wrappers.
#
# Env:
#   WORKER_MODEL=provider/model  Override the bundled worker model.
#   SKIP_HERDR_SKILL=1          Skip the global Herdr skill installation.
#   PI_CODING_AGENT_DIR=path    Override Pi's agent directory.
#   BIN_DIR=path                Override the wrapper installation directory.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
PROFILE_DIR="$PI_AGENT_DIR/herdr-subagents/agents"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
HERDR_SUBAGENTS_REPO="maxedapps/pi-subagents-herdr"
HERDR_SUBAGENTS_COMMIT="3af3865a58ea4c551c3ea7b099fe8a9ea42cba83"
HERDR_SUBAGENTS_SOURCE="git:github.com/$HERDR_SUBAGENTS_REPO@$HERDR_SUBAGENTS_COMMIT"
MIN_GIT="2.45.0"
MIN_NODE="22.19.0"
GIT_VERSION=""

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m OK\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m XX\033[0m %s\n' "$*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }
is_mac() { [ "$(uname -s)" = "Darwin" ]; }

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
  has node || return 1
  node -e '
    const [actual, minimum] = process.argv.slice(1).map((value) =>
      value.split(".").map(Number)
    );
    for (let index = 0; index < 3; index++) {
      if (actual[index] > minimum[index]) process.exit(0);
      if (actual[index] < minimum[index]) process.exit(1);
    }
  ' "$(node -p 'process.versions.node')" "$MIN_NODE"
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
  log "Checking prerequisites"
  require_git_version
  has curl || die "curl is required"
  has mise || die "mise is required; install it first from https://mise.jdx.dev"

  log "Installing mise-managed Node, Pi, and Herdr"
  mise -C "$REPO_ROOT" trust "$REPO_ROOT/mise/config.toml" >/dev/null
  if ! node_ok || ! has npx; then
    mise -C "$REPO_ROOT" install node npm
  fi
  mise -C "$REPO_ROOT" install pi herdr
  mise reshim
  export PATH="$HOME/.local/share/mise/shims:$PATH"
  hash -r

  node_ok || die "node >= $MIN_NODE is required (current: $(node -v 2>/dev/null || echo none))"
  has pi || die "pi is not on PATH after mise install"
  has herdr || die "herdr is not on PATH after mise install"
  ok "git $GIT_VERSION, node $(node -v), pi $(pi --version | head -n1), $(herdr --version | head -n1)"

  log "Installing repository-owned Pi extensions"
  mkdir -p "$PI_AGENT_DIR/extensions"
  sync_file "$DIR/extensions/reviewer-git.ts" "$PI_AGENT_DIR/extensions/reviewer-git.ts"

  log "Installing Herdr agent integrations"
  herdr integration install pi
  if has copilot; then
    mkdir -p "${COPILOT_HOME:-$HOME/.copilot}"
    herdr integration install copilot
  else
    warn "copilot CLI is not installed; skipping its Herdr integration"
  fi

  log "Installing pinned Pi Herdr subagents extension"
  packages="$(pi list 2>/dev/null || true)"
  if grep -Fq "npm:@maxedapps/pi-subagents-herdr" <<<"$packages"; then
    die "remove npm:@maxedapps/pi-subagents-herdr before installing the pinned Git source"
  fi

  installed_git_source="$(grep -E 'git:github\.com/maxedapps/pi-subagents-herdr(@|$)' <<<"$packages" | head -n1 || true)"
  if [ -n "$installed_git_source" ] && [ "$installed_git_source" != "  $HERDR_SUBAGENTS_SOURCE" ] && [ "$installed_git_source" != "$HERDR_SUBAGENTS_SOURCE" ]; then
    die "another Git source is configured for $HERDR_SUBAGENTS_REPO: $installed_git_source"
  fi

  if grep -Fq "$HERDR_SUBAGENTS_SOURCE" <<<"$packages"; then
    pi update --extension "$HERDR_SUBAGENTS_SOURCE"
  else
    pi install "$HERDR_SUBAGENTS_SOURCE"
  fi
  ok "pinned $HERDR_SUBAGENTS_REPO at $HERDR_SUBAGENTS_COMMIT"

  if grep -Fq "npm:pi-subagents" <<<"$packages"; then
    warn "npm:pi-subagents is still installed; verify the Herdr stack before removing it"
  fi

  if [ "${SKIP_HERDR_SKILL:-0}" != "1" ]; then
    log "Installing the official Herdr skill"
    npx -y skills add herdrdev/herdr --skill herdr --agent pi github-copilot -g -y
  fi

  log "Installing Pi subagent profiles"
  mkdir -p "$PROFILE_DIR"
  for profile in "$DIR"/profiles/*.md; do
    sync_file "$profile" "$PROFILE_DIR/$(basename "$profile")"
  done

  if [ -n "${WORKER_MODEL:-}" ]; then
    log "Installing worker model override: $WORKER_MODEL"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    worker_url="https://raw.githubusercontent.com/$HERDR_SUBAGENTS_REPO/$HERDR_SUBAGENTS_COMMIT/agents/worker.md"
    curl -fsSL "$worker_url" > "$tmp/worker-upstream.md"
    awk -v model="$WORKER_MODEL" '
    NR == 1 && /^---[[:space:]]*$/ { in_frontmatter = 1; print; next }
    in_frontmatter && /^model:/ {
      print "model: " model
      model_written = 1
      next
    }
    in_frontmatter && /^---[[:space:]]*$/ {
      if (!model_written) print "model: " model
      in_frontmatter = 0
      print
      next
    }
    { print }
  ' "$tmp/worker-upstream.md" > "$tmp/worker.md"
    sync_file "$tmp/worker.md" "$PROFILE_DIR/worker.md"
  fi

  if is_mac; then
    log "Installing xbuild"
    has lockf || die "macOS lockf is required by xbuild"
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

Pinned extension:
  $HERDR_SUBAGENTS_SOURCE

Enable the coordinator workflow in a repository:
  cp "$DIR/templates/AGENTS.md" ./AGENTS.md

Start Pi from a Herdr pane, then smoke test with:
  Use a scout subagent to map how this project is structured.
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
