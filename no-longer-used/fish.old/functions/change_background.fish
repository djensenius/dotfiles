# Modified from
# https://arslan.io/2021/02/15/automatic-dark-mode-for-terminal-applications/

function change_background --argument mode_setting
  # change background to the given mode. If mode is missing,
  # we try to deduct it from the system settings.

  set -l mode "dark" # default value
  if test -z $mode_setting
    set -l val (defaults read -g AppleInterfaceStyle) >/dev/null
    if test $status -eq 0
      set mode "dark"
    end
  else
    switch $mode_setting
      case light
        # osascript -l JavaScript -e "Application('System Events').appearancePreferences.darkMode = false" >/dev/null
        set mode "light"
      case dark
        # osascript -l JavaScript -e "Application('System Events').appearancePreferences.darkMode = true" >/dev/null
        set mode "dark"
    end
  end

  # well, seems like there is no proper way to send a command to
  # Vim as a client. Luckily we're using tmux, which means we can
  # iterate over all vim sessions and change the background ourself.
  set -l tmux_wins (/usr/local/bin/tmux list-windows -t coding)

  for wix in (/usr/local/bin/tmux list-windows -t coding -F 'coding:#{window_index}')
    for pix in (/usr/local/bin/tmux list-panes -F 'coding:#{window_index}.#{pane_index}' -t $wix)
      set -l is_vim "ps -o state= -o comm= -t '#{pane_tty}'  | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?\$'"
      /usr/local/bin/tmux if-shell -t "$pix" "$is_vim" "send-keys -t $pix escape ENTER"
      /usr/local/bin/tmux if-shell -t "$pix" "$is_vim" "send-keys -t $pix ':call ChangeBackground(\"$mode\")' ENTER"
    end
  end

switch $mode
  case light
    echo -e "\033Ptmux;\033\033]50;SetProfile=Light\007\033\\"
    set -U fish_color_error 9177E5
    set -U fish_color_end 02BDBD
    set -U fish_color_redirection 248E8E
    set -U fish_color_quote 4C3499
    set -U fish_color_command 164CC9
    set -U fish_color_normal normal
    set -U fish_color_selection white --bold --background=brblack
    set -U fish_color_search_match bryellow --background=brblack
    set -U fish_color_history_current --bold
    set -U fish_color_operator 00a6b2
    set -U fish_color_escape 00a6b2
    set -U fish_color_cwd green
    set -U fish_color_cwd_root red
    set -U fish_color_valid_path --underline
    set -U fish_color_autosuggestion 7596E4
    set -U fish_color_user brgreen
    set -U fish_color_host normal
    set -U fish_color_cancel -r
    set -U fish_pager_color_completion normal
    set -U fish_pager_color_description B3A06D yellow
    set -U fish_pager_color_prefix white --bold --underline
    set -U fish_pager_color_progress brwhite --background=cyan
    set -x ITERM_PROFILE Light
    cp ~/.config/starship-light.toml ~/.config/starship.toml
    tmux source-file ~/config-files/tmux-light.conf
  case dark
    echo -e "\033Ptmux;\033\033]50;SetProfile=Default\007\033\\"
    set -U fish_color_error FFB86C
    set -U fish_color_end 50FA7B
    set -U fish_color_redirection 8BE9FD
    set -U fish_color_quote F1FA8C
    set -U fish_color_command F8F8F2
    set -U fish_color_normal normal
    set -U fish_color_selection white --bold --background=brblack
    set -U fish_color_search_match bryellow --background=brblack
    set -U fish_color_history_current --bold
    set -U fish_color_operator 00a6b2
    set -U fish_color_escape 00a6b2
    set -U fish_color_cwd green
    set -U fish_color_cwd_root red
    set -U fish_color_valid_path --underline
    set -U fish_color_autosuggestion BD93F9
    set -U fish_color_user brgreen
    set -U fish_color_host normal
    set -U fish_color_cancel -r
    set -U fish_pager_color_completion normal
    set -U fish_pager_color_description B3A06D yellow
    set -U fish_pager_color_prefix white --bold --underline
    set -U fish_pager_color_progress brwhite --background=cyan
    set -x ITERM_PROFILE Default
    tmux source-file ~/config-files/tmux.conf
    cp ~/.config/starship-dark.toml ~/.config/starship.toml
  end
end
