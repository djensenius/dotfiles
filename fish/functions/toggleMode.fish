function toggleMode
  if $DARK_MODE
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
    set -Ux DARK_MODE false
    cp ~/.config/starship-light.toml ~/.config/starship.toml
    rm ~/.darkmode
  else
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
    set -Ux DARK_MODE true
    cp ~/.config/starship-dark.toml ~/.config/starship.toml
    touch ~/.darkmode
  end
end
