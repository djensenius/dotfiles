#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

mise_tools() {
    awk '
        /^\[tools\]/ { in_tools=1; next }
        /^\[/ { in_tools=0 }
        in_tools && /^[[:space:]]*[^#[:space:]][^=]*=/ {
            key=$0
            sub(/=.*/, "", key)
            gsub(/^[[:space:]\"]+|[[:space:]\"]+$/, "", key)
            if (key ~ /:/) next
            sub(/@.*/, "", key)
            print key
        }
    ' "$ROOT/mise/config.toml" | sort -u
}

brew_names() {
    awk '
        /^[[:space:]]*brew[[:space:]]+"/ {
            line=$0
            sub(/^[[:space:]]*brew[[:space:]]+"/, "", line)
            sub(/".*/, "", line)
            n=split(line, parts, "/")
            print parts[n]
        }
        /^[[:space:]]*cask[[:space:]]+"/ {
            line=$0
            sub(/^[[:space:]]*cask[[:space:]]+"/, "", line)
            sub(/".*/, "", line)
            print line
        }
    ' "$ROOT/mac/Brewfile" "$ROOT/mac/Brewfile.apps" | sort -u
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mise_tools >"$tmp/mise"
brew_names >"$tmp/brew"
# mise itself is intentionally installed by Homebrew.
grep -vxF mise "$tmp/mise" >"$tmp/mise-no-brew-exception"

if overlap="$(comm -12 "$tmp/mise-no-brew-exception" "$tmp/brew")" && [ -n "$overlap" ]; then
    printf 'Brewfile entries overlap mise-owned tools:\n%s\n' "$overlap" >&2
    exit 1
fi

printf 'ok Brewfiles do not overlap mise-owned tools\n'
