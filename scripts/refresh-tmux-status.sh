#!/usr/bin/env bash
# Helper script to refresh tmux status when background installations start/stop

# Check if we're in a tmux session
if [ -n "$TMUX" ]; then
    # Refresh the status line immediately
    tmux refresh-client -S
fi