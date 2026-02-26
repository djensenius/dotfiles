# Theme mode initialization — sets env vars based on current theme.
# Uses fish universal variable THEME_MODE for instant propagation
# across all running shells when theme changes.

# On shell startup: ensure THEME_MODE is set
if not set -q THEME_MODE
    # Read from state file or detect
    if test -f "$HOME/.config/theme-mode"
        set -U THEME_MODE (cat "$HOME/.config/theme-mode")
    else if test (uname) = Darwin
        if defaults read -g AppleInterfaceStyle >/dev/null 2>&1
            set -U THEME_MODE dark
        else
            set -U THEME_MODE light
        end
    else
        set -U THEME_MODE dark
    end
end

# Event handler: fires whenever THEME_MODE changes (including from other shells)
function _theme_apply --on-variable THEME_MODE
    if test "$THEME_MODE" = light
        set -gx BAT_THEME Catppuccin-latte
        set -gx DARK_MODE false
        set -gx FZF_DEFAULT_OPTS '--color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39 --color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78 --color=marker:#7287fd,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39 --color=selected-bg:#bcc0cc --multi'
    else
        set -gx BAT_THEME Catppuccin-mocha
        set -gx DARK_MODE true
        set -gx FZF_DEFAULT_OPTS '--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --multi'
    end
end

# Apply theme on shell init
_theme_apply
