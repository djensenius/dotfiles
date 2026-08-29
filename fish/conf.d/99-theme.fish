# Theme mode management — sets env vars for external tools based on terminal color scheme.
# Fish 4.x auto-detects dark/light via $fish_terminal_color_theme (OSC 11 query).
# This handler fires on terminal color scheme changes AND on shell startup.

function _theme_apply --on-variable fish_terminal_color_theme
    if test "$fish_terminal_color_theme" = light
        set -gx DARK_MODE false
        set -gx COLORFGBG '0;15'
        set -gx FZF_DEFAULT_OPTS '--color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39 --color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78 --color=marker:#7287fd,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39 --color=selected-bg:#bcc0cc --multi'

        # Fish syntax highlighting — Catppuccin Latte
        set -g fish_color_normal 4c4f69
        set -g fish_color_command 1e66f5
        set -g fish_color_keyword d20f39
        set -g fish_color_quote 40a02b
        set -g fish_color_redirection ea76cb
        set -g fish_color_end fe640b
        set -g fish_color_error d20f39
        set -g fish_color_param dd7878
        set -g fish_color_option 40a02b
        set -g fish_color_comment 8c8fa1
        set -g fish_color_selection --background=ccd0da
        set -g fish_color_search_match --background=ccd0da
        set -g fish_color_operator ea76cb
        set -g fish_color_escape e64553
        set -g fish_color_autosuggestion 9ca0b0
        set -g fish_color_cancel d20f39
        set -g fish_color_cwd df8e1d
        set -g fish_color_user 179299
        set -g fish_color_host 1e66f5
        set -g fish_color_host_remote 40a02b
        set -g fish_color_status d20f39
        set -g fish_color_gray 9ca0b0
        set -g fish_pager_color_completion 4c4f69
        set -g fish_pager_color_description 9ca0b0
        set -g fish_pager_color_prefix ea76cb
        set -g fish_pager_color_progress 9ca0b0
    else
        set -gx DARK_MODE true
        set -gx COLORFGBG '15;0'
        set -gx FZF_DEFAULT_OPTS '--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --multi'

        # Fish syntax highlighting — Catppuccin Mocha
        set -g fish_color_normal cdd6f4
        set -g fish_color_command 89b4fa
        set -g fish_color_keyword f38ba8
        set -g fish_color_quote a6e3a1
        set -g fish_color_redirection f5c2e7
        set -g fish_color_end fab387
        set -g fish_color_error f38ba8
        set -g fish_color_param f2cdcd
        set -g fish_color_option a6e3a1
        set -g fish_color_comment 7f849c
        set -g fish_color_selection --background=313244
        set -g fish_color_search_match --background=313244
        set -g fish_color_operator f5c2e7
        set -g fish_color_escape eba0ac
        set -g fish_color_autosuggestion 6c7086
        set -g fish_color_cancel f38ba8
        set -g fish_color_cwd f9e2af
        set -g fish_color_user 94e2d5
        set -g fish_color_host 89b4fa
        set -g fish_color_host_remote a6e3a1
        set -g fish_color_status f38ba8
        set -g fish_color_gray 6c7086
        set -g fish_pager_color_completion cdd6f4
        set -g fish_pager_color_description 6c7086
        set -g fish_pager_color_prefix f5c2e7
        set -g fish_pager_color_progress 6c7086
    end
end

# Apply theme on shell init
_theme_apply
