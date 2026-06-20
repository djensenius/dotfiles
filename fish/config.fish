# Interactive-only setup. Everything else lives in conf.d/*.fish

# Security-sensitive mise settings must come from env because ~/.config/mise
# is symlinked into this repo and mise treats the real path as non-global.
set -gx MISE_TRUSTED_CONFIG_PATHS "$HOME/Developer:$HOME/Code:/workspaces"
set -gx MISE_GITHUB_CREDENTIAL_COMMAND "gh auth token"
set -gx MISE_PARANOID false
set -gx MISE_YES false

# Initialize mise early so tools are available in all shells
if command -q mise
    # Avoid mise's default prompt hook; update once on startup and again only after cd.
    mise activate fish --no-hook-env | source
    mise hook-env -s fish | source

    function __mise_cd_hook --on-variable PWD --description 'Update mise environment when changing directories'
        mise hook-env -s fish | source
    end
end

if status is-interactive
    # Codespace path reconstruction (fixes PATH issues in GitHub Codespaces)
    if test -d /workspaces
        __fish_reconstruct_path
    end

    # Prompt and tools that hook into the interactive shell
    starship init fish | source
    zoxide init fish | source
    fzf --fish | source

    # Atuin (login once on Codespaces; then init every interactive shell)
    if test -d /workspaces
        if command -q atuin
            # Check if already logged in by looking for Username in status
            if not ~/.cargo/bin/atuin status | grep -q "Username:"
                ~/.cargo/bin/atuin login -u $ATUIN_USERNAME -p $ATUIN_PASSWORD -k $ATUIN_KEY
            end
        end
    end
    atuin init fish | source

    # Optional extra plugin
    command -q pay-respects; and pay-respects fish | source
end
