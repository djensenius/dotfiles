#!/usr/bin/env bash
# Background installation indicator for tmux status line

# Spinner animation frames (same as lualine)
SPINNER_FRAMES=("∙" "●" "◉" "◎")

# PID files for background installations
RUST_PID_FILE=~/.dotfiles_rust_install.pid
NPM_PID_FILE=~/.dotfiles_npm_install.pid

# Check if any background installations are running
rust_running=false
npm_running=false

if [ -f "$RUST_PID_FILE" ]; then
    rust_pid=$(cat "$RUST_PID_FILE" 2>/dev/null)
    if [ -n "$rust_pid" ] && ps -p "$rust_pid" > /dev/null 2>&1; then
        rust_running=true
    fi
fi

if [ -f "$NPM_PID_FILE" ]; then
    npm_pid=$(cat "$NPM_PID_FILE" 2>/dev/null)
    if [ -n "$npm_pid" ] && ps -p "$npm_pid" > /dev/null 2>&1; then
        npm_running=true
    fi
fi

# If nothing is running, output nothing (indicator disappears)
if [ "$rust_running" = false ] && [ "$npm_running" = false ]; then
    exit 0
fi

# Get current spinner frame based on seconds
current_second=$(date +%s)
frame_index=$((current_second % ${#SPINNER_FRAMES[@]}))
spinner_frame=${SPINNER_FRAMES[$frame_index]}

# Build status message with Nerd Font symbols
status_parts=()
if [ "$rust_running" = true ]; then
    status_parts+=("") # Nerd Font Rust symbol
fi
if [ "$npm_running" = true ]; then
    status_parts+=("") # Nerd Font NPM symbol
fi

# Join parts with space and add spinner
status_text=$(IFS=' '; echo "${status_parts[*]}")

# Output with catppuccin mocha colors (blue for info)
echo "#[fg=#89b4fa]${spinner_frame} ${status_text}#[default]"
