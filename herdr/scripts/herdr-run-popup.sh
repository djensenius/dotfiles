#!/usr/bin/env bash
# Herdr equivalent of tmux's `bind / command-prompt "splitw '%%'"`.
#
# Prompts for a command, runs it in the popup, then holds the popup open so the
# output is readable — tmux kept the split around until the process exited.
set -uo pipefail

printf 'run: '
IFS= read -r cmd || exit 0
[ -z "$cmd" ] && exit 0

"${SHELL:-/bin/sh}" -lc "$cmd"
status=$?

printf '\n[exit %s] press enter to close' "$status"
IFS= read -r _ || true
exit "$status"
