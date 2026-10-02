#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${HERDR_CONFIG_PATH:-$HOME/.config/herdr/config.toml}"
TMP_STATUS="$(mktemp "${TMPDIR:-/tmp}/herdr-image-doctor-status.XXXXXX")"
TMP_STATUS_ERR="$(mktemp "${TMPDIR:-/tmp}/herdr-image-doctor-status-err.XXXXXX")"
trap 'rm -f "$TMP_STATUS" "$TMP_STATUS_ERR"' EXIT

section() { printf '\n== %s ==\n' "$1"; }
kv() { printf '%-28s %s\n' "$1" "${2:-}"; }

section "terminal"
kv "TERM" "${TERM:-unset}"
kv "TERM_PROGRAM" "${TERM_PROGRAM:-unset}"
kv "KITTY_WINDOW_ID" "${KITTY_WINDOW_ID:-unset}"
kv "WEZTERM_PANE" "${WEZTERM_PANE:-unset}"
kv "SSH_CONNECTION" "${SSH_CONNECTION:+set}"

section "herdr config"
kv "config" "$CONFIG_PATH"
if [ -f "$CONFIG_PATH" ]; then
  if awk '
    /^\[[^]]+\]/ { section=$0 }
    section == "[terminal]" && $1 == "kitty_graphics" && $0 ~ /true/ { found=1 }
    END { exit found ? 0 : 1 }
  ' "$CONFIG_PATH"; then
    kv "terminal.kitty_graphics" "true"
  else
    kv "terminal.kitty_graphics" "missing or not true"
  fi

  if awk '
    /^\[[^]]+\]/ { section=$0 }
    section == "[experimental]" && $1 == "kitty_graphics" && $0 ~ /true/ { found=1 }
    END { exit found ? 0 : 1 }
  ' "$CONFIG_PATH"; then
    kv "experimental.kitty_graphics" "true (deprecated compatibility key)"
  fi
else
  kv "config" "missing"
fi

section "herdr status"
if command -v herdr >/dev/null 2>&1; then
  herdr --version || true
  if command -v python3 >/dev/null 2>&1 && herdr status --json >"$TMP_STATUS" 2>"$TMP_STATUS_ERR"; then
    python3 - <<'PY' "$TMP_STATUS"
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
client = data.get('client') or {}
server = data.get('server') or {}
print(f"client.version              {client.get('version', 'unknown')}")
print(f"server.version              {server.get('version', 'unknown')}")
print(f"server.running              {server.get('running', 'unknown')}")
print(f"server.compatible           {server.get('compatible', 'unknown')}")
print(f"server.binary_stale         {server.get('server_binary_stale', 'unknown')}")
print(f"endpoint.capabilities       {', '.join(client.get('endpoint_capabilities') or [])}")
PY
  else
    herdr status || true
    [ ! -s "$TMP_STATUS_ERR" ] || cat "$TMP_STATUS_ERR" >&2
  fi
else
  kv "herdr" "not on PATH"
fi

section "diagnosis"
cat <<'EOF'
For remote Herdr images, check both ends:
1. The remote server's config must have [terminal] kitty_graphics = true so it parses Kitty graphics from pane PTYs.
2. The local client config must have [terminal] kitty_graphics = true and the outer terminal must support Kitty graphics.
3. Restart/reload the remote server and detach/reattach the local client after changing either config.
4. If server.binary_stale is true, run `herdr update --handoff` or restart the Herdr server so the client/server versions match.
5. If images work over plain SSH but not Herdr remote, collect `herdr status --json`, this script's output on both ends, and the exact app command (for example `kitten icat`, `timg`, or `yazi`).
EOF
