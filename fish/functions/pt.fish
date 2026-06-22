function pt --description "Start or attach the personal tmux session"
    set -l session personal

    if tmux has-session -t "$session" 2>/dev/null
        if set -q TMUX
            tmux switch-client -t "$session"
        else
            tmux attach-session -t "$session"
        end
        return
    end

    tmux new-session -d -s "$session" -n Monitor "fish -lc 'tmux set-window-option -t1 automatic-rename on; btm --battery; exec fish'" \; \
        split-window -t "$session:1" -v "fish -lc 'gping -c blue google.com -c red aka.ms -c green github.com; exec fish'" \; \
        split-window -t "$session:1" -v "fish -lc 'clear; exec fish'" \; \
        select-layout -t "$session:1" main-horizontal \; \
        new-window -t "$session:2" -n Code "fish -lc 'tmux set-window-option -t2 automatic-rename on; nvim; exec fish'" \; \
        select-window -t "$session:1" \; \
        select-pane -t "$session:1.0"
    or return

    if set -q TMUX
        tmux switch-client -t "$session"
    else
        tmux attach-session -t "$session"
    end
end
