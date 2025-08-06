# Interactive-only setup. Everything else lives in conf.d/*.fish

if status is-interactive
    # Prompt and tools that hook into the interactive shell
    starship init fish | source
    zoxide init fish | source
    fzf --fish | source

    # Atuin (login once on Codespaces; then init every interactive shell)
    if test -d /workspaces
        if not test -e ~/.atuin_logged_in
            command -q atuin; and ~/.cargo/bin/atuin login -u $ATUIN_USERNAME -p $ATUIN_PASSWORD -k $ATUIN_KEY
            touch ~/.atuin_logged_in
        end
    end
    atuin init fish | source

    # Optional extra plugin
    command -q pay-respects; and pay-respects fish | source
end
