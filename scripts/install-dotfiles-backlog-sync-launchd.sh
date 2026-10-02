#!/usr/bin/env bash
set -euo pipefail

LABEL="com.djensenius.dotfiles.backlog-sync"
BINARY="$(command -v backlog-sync || true)"
ROOT=""
STDOUT_LOG="/tmp/dotfiles-backlog-sync.out.log"
STDERR_LOG="/tmp/dotfiles-backlog-sync.err.log"
LOAD=0
ALLOW_NON_MAIN_ROOT=0

usage() {
  cat <<'USAGE'
Usage: scripts/install-dotfiles-backlog-sync-launchd.sh [--root <repo-root>] [--binary <path>] [--stdout-log <path>] [--stderr-log <path>] [--load] [--allow-non-main-root]

Renders and installs ~/Library/LaunchAgents/com.djensenius.dotfiles.backlog-sync.plist
for this repository's Backlog.md to GitHub Project mirror. The launchd job runs
backlog-sync with -root, -config, -no-inbox, and -verbose so inbox import remains
manual/disabled for unattended runs.

Use --load only from the long-lived main checkout after the mirror config has
landed there. backlog-sync intentionally reads local task worktrees, but the
LaunchAgent root itself must not point at a disposable task worktree that will be
removed after merge.

Options:
  --root <repo-root>       Repository root to mirror (default: git top-level of cwd)
  --binary <path>          backlog-sync binary (default: first backlog-sync on PATH)
  --stdout-log <path>      launchd stdout log (default: /tmp/dotfiles-backlog-sync.out.log)
  --stderr-log <path>      launchd stderr log (default: /tmp/dotfiles-backlog-sync.err.log)
  --load                   Bootstrap and kickstart the LaunchAgent after writing it
  --allow-non-main-root    Allow --load from a non-main checkout (for diagnostics only)
USAGE
}

require_value() {
  local option="$1"
  if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
    echo "missing value for $option" >&2
    usage >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) require_value "$1" "${2:-}"; ROOT="$2"; shift 2 ;;
    --binary) require_value "$1" "${2:-}"; BINARY="$2"; shift 2 ;;
    --stdout-log) require_value "$1" "${2:-}"; STDOUT_LOG="$2"; shift 2 ;;
    --stderr-log) require_value "$1" "${2:-}"; STDERR_LOG="$2"; shift 2 ;;
    --load) LOAD=1; shift ;;
    --allow-non-main-root) ALLOW_NON_MAIN_ROOT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$ROOT" ]]; then
  ROOT="$(git rev-parse --show-toplevel)"
fi
ROOT="$(cd "$ROOT" && pwd -P)"
CONFIG="${ROOT}/.backlog-sync.json"
TEMPLATE="${ROOT}/launchd/${LABEL}.plist.template"
PLIST_DIR="${HOME}/Library/LaunchAgents"
PLIST="${PLIST_DIR}/${LABEL}.plist"

for absolute_path in "$BINARY" "$ROOT" "$CONFIG" "$STDOUT_LOG" "$STDERR_LOG"; do
  if [[ "$absolute_path" != /* ]]; then
    echo "expected absolute path: $absolute_path" >&2
    exit 2
  fi
done

if [[ ! -x "$BINARY" ]]; then
  echo "backlog-sync binary is not executable: $BINARY" >&2
  exit 1
fi
if [[ ! -f "$CONFIG" ]]; then
  echo "missing backlog-sync config: $CONFIG" >&2
  exit 1
fi
if [[ ! -f "$TEMPLATE" ]]; then
  echo "missing launchd template: $TEMPLATE" >&2
  exit 1
fi

if [[ "$ALLOW_NON_MAIN_ROOT" -ne 1 ]]; then
  current_branch="$(git -C "$ROOT" branch --show-current)"
  main_branch="$(python3 - <<'PY' "$CONFIG"
import json
import sys
with open(sys.argv[1], encoding="utf-8") as f:
    print(json.load(f).get("mainBranch") or "main")
PY
)"
  if [[ "$current_branch" != "$main_branch" ]]; then
    cat >&2 <<EOF
refusing to load ${LABEL} from ${ROOT}: current branch is ${current_branch:-detached}, expected ${main_branch}

Render and install the LaunchAgent from the long-lived main checkout after this
branch is merged, for example:
  cd /Users/david/Developer/dotfiles
  scripts/install-dotfiles-backlog-sync-launchd.sh --load

Use --allow-non-main-root only for short-lived diagnostics, then bootout the job
before deleting that worktree.
EOF
    exit 2
  fi
fi

mkdir -p "$PLIST_DIR" "$(dirname "$STDOUT_LOG")" "$(dirname "$STDERR_LOG")"

python3 - "$TEMPLATE" "$PLIST" "$LABEL" "$BINARY" "$ROOT" "$CONFIG" \
  "$STDOUT_LOG" "$STDERR_LOG" \
  "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" "$HOME" <<'PY'
import html
import pathlib
import sys

template_path = pathlib.Path(sys.argv[1])
plist_path = pathlib.Path(sys.argv[2])
label, binary, root, config, stdout_log, stderr_log, path, home = sys.argv[3:11]
replacements = {
    "__LABEL__": label,
    "__BINARY_PATH__": binary,
    "__REPO_ROOT__": root,
    "__CONFIG_PATH__": config,
    "__STDOUT_LOG__": stdout_log,
    "__STDERR_LOG__": stderr_log,
    "__PATH__": path,
    "__HOME__": home,
}
rendered = template_path.read_text()
for placeholder, value in replacements.items():
    rendered = rendered.replace(placeholder, html.escape(value, quote=True))
plist_path.write_text(rendered)
PY

plutil -lint "$PLIST"
echo "wrote $PLIST"

if [[ "$LOAD" -eq 1 ]]; then
  launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"
  launchctl kickstart -k "gui/$(id -u)/${LABEL}"
fi
