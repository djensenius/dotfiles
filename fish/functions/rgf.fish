function rgp --description "ripgrep with (delta) pager"
    rg --json $argv | delta
end

function rgf --description "ripgrep with fzf"
    if test -t 0
        rg --color=always --line-number --no-heading --smart-case "$argv" |
            fzf --ansi \
                --color "hl:-1:underline,hl+:-1:underline:reverse" \
                --delimiter : \
                --preview 'bat --color=always {1} --highlight-line {2}' \
                --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
                --bind 'enter:become(nvim {1} +{2})'
    else
        rg --color=always --smart-case "$argv" | fzf --ansi
    end
end
