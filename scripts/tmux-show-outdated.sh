#!/usr/bin/env bash
PLUGIN_DIR="$HOME/.config/tmux/plugins/tmux-outdated-packages"
SHOW_STATUS_SCRIPT="$PLUGIN_DIR/scripts/show-status.sh"

if [ -x "$SHOW_STATUS_SCRIPT" ]; then
    OUTPUT=$("$SHOW_STATUS_SCRIPT")
    # Trim whitespace to check if empty
    TRIMMED=$(echo "$OUTPUT" | xargs)
    
    if [ -n "$TRIMMED" ]; then
        # Output the full tmux format string
        # We use the raw OUTPUT to preserve internal spacing if any, but we might want to control padding
        # The original module had: ... 󰏖 ... #(script) ...
        # We replicate that structure but conditionally.
        
        echo "#[fg=#{E:@thm_peach}]#{?#{==:#{@catppuccin_status_connect_separator},yes},,#[bg=default]}#{@catppuccin_status_left_separator}#[fg=#{E:@thm_crust},bg=#{E:@thm_peach}]󰏖 #{@catppuccin_status_middle_separator}#[fg=#{E:@thm_fg},bg=#{E:@catppuccin_status_module_text_bg}] $OUTPUT#[fg=#{E:@catppuccin_status_module_text_bg}]#{?#{==:#{@catppuccin_status_connect_separator},yes},,#[bg=default]}#{@catppuccin_status_right_separator}"
    fi
fi
