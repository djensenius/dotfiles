# Modified from
# https://arslan.io/2021/02/15/automatic-dark-mode-for-terminal-applications/

function change_background --argument mode_setting
    # change background to the given mode. If mode is missing,
    # we try to deduct it from the system settings.

    set -l mode dark # default value
    if test -z $mode_setting
        set -l val (defaults read -g AppleInterfaceStyle) >/dev/null
        if test $status -eq 0
            set mode dark
        end
    else
        switch $mode_setting
            case light
                # osascript -l JavaScript -e "Application('System Events').appearancePreferences.darkMode = false" >/dev/null
                set mode light
            case dark
                # osascript -l JavaScript -e "Application('System Events').appearancePreferences.darkMode = true" >/dev/null
                set mode dark
        end
    end

    # well, seems like there is no proper way to send a command to
    # Vim as a client. Luckily we're using tmux, which means we can
    # iterate over all vim sessions and change the background ourself.
    set -l tmux_wins (tmux list-windows -t coding)

    for wix in (tmux list-windows -t coding -F 'coding:#{window_index}')
        for pix in (tmux list-panes -F 'coding:#{window_index}.#{pane_index}' -t $wix)
            set -l is_vim "ps -o state= -o comm= -t '#{pane_tty}'  | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?\$'"
            tmux if-shell -t "$pix" "$is_vim" "send-keys -t $pix escape ENTER"
            tmux if-shell -t "$pix" "$is_vim" "send-keys -t $pix ':call ChangeBackground(\"$mode\")' ENTER"
        end
    end

    switch $mode
        case light
            # Catppuccin Latte
            echo -e "\033Ptmux;\033\033]50;SetProfile=Light\007\033\\"
            set -U fish_color_autosuggestion 9ca0b0
            set -U fish_color_cancel d20f39
            set -U fish_color_command 1e66f5
            set -U fish_color_comment 8c8fa1
            set -U fish_color_cwd df8e1d
            set -U fish_color_cwd_root red
            set -U fish_color_end fe640b
            set -U fish_color_error d20f39
            set -U fish_color_escape e64553
            set -U fish_color_gray 9ca0b0
            set -U fish_color_history_current --bold
            set -U fish_color_host 1e66f5
            set -U fish_color_host_remote 40a02b
            set -U fish_color_keyword d20f39
            set -U fish_color_match --background=brblue
            set -U fish_color_normal 4c4f69
            set -U fish_color_operator ea76cb
            set -U fish_color_option 40a02b
            set -U fish_color_param dc8a78
            set -U fish_color_quote 40a02b
            set -U fish_color_redirection ea76cb
            set -U fish_color_search_match --background=ccd0da
            set -U fish_color_selection --background=ccd0da
            set -U fish_color_status d20f39
            set -U fish_color_user 179299
            set -U fish_color_valid_path --underline
            set -U fish_pager_color_completion 4c4f69
            set -U fish_pager_color_description 9ca0b0
            set -U fish_pager_color_prefix ea76cb
            set -U fish_pager_color_progress 9ca0b0
            cp ~/.config/starship-light.toml ~/.config/starship.toml
            tmux source-file ~/.config/tmux/tmux-light.conf
        case dark
            # Catppuccin Mocha
            echo -e "\033Ptmux;\033\033]50;SetProfile=Default\007\033\\"
            set -U fish_color_autosuggestion 6c7086
            set -U fish_color_cancel f38ba8
            set -U fish_color_command 89b4fa
            set -U fish_color_comment 7f849c
            set -U fish_color_cwd f9e2af
            set -U fish_color_cwd_root red
            set -U fish_color_end fab387
            set -U fish_color_error f38ba8
            set -U fish_color_escape eba0ac
            set -U fish_color_gray 6c7086
            set -U fish_color_history_current --bold
            set -U fish_color_host 89b4fa
            set -U fish_color_host_remote a6e3a1
            set -U fish_color_keyword f38ba8
            set -U fish_color_match --background=brblue
            set -U fish_color_normal cdd6f4
            set -U fish_color_operator f5c2e7
            set -U fish_color_option a6e3a1
            set -U fish_color_param f2cdcd
            set -U fish_color_quote a6e3a1
            set -U fish_color_redirection f5c2e7
            set -U fish_color_search_match --background=313244
            set -U fish_color_selection --background=313244
            set -U fish_color_status f38ba8
            set -U fish_color_user 94e2d5
            set -U fish_color_valid_path --underline
            set -U fish_pager_color_completion cdd6f4
            set -U fish_pager_color_description 6c7086
            set -U fish_pager_color_prefix f5c2e7
            set -U fish_pager_color_progress 6c7086
            tmux source-file ~/.config/tmux/tmux.conf
            cp ~/.config/starship-dark.toml ~/.config/starship.toml
    end
end
