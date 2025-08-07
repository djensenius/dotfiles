# Abbreviations (expand as you type). Guard against duplicates.

function __abbr_add --argument-names name expansion
    if not abbr --query $name
        abbr --add $name $expansion
    end
end

# Your config.fish abbreviations
__abbr_add monolith 'gh cs create -R github/github -m xLargePremiumLinux --devcontainer-path .devcontainer/devcontainer.json --status'
__abbr_add youtub-dl yt-dlp
__abbr_add vim nvim
__abbr_add vi nvim
__abbr_add clear-tmux-window 'tmux set-window-option -t1 automatic-rename on'
__abbr_add kw 'curl https://wttr.in/Kitchener'

# From your previous fish_variables
__abbr_add brewu 'brew update; brew upgrade; brew upgrade --cask'
__abbr_add cat bat
__abbr_add cd z
__abbr_add du dust
__abbr_add grep rgf
__abbr_add lls 'eza --long --header --git'
__abbr_add ls eza
__abbr_add more most
__abbr_add npmu 'npm -g outdated; npm update -g'
__abbr_add ping gping
__abbr_add preview 'fzf --preview '\''bat --color "always" {}'\'''
__abbr_add restartdock 'rm /var/folders/*/*/*/com.apple.dock.iconcache; killall Dock'
__abbr_add top btm
__abbr_add tree 'eza --tree --level=2 --long --header --git'
__abbr_add weather 'curl https://wttr.in'
