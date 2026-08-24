# Interactive-only setup. Everything else lives in conf.d/*.fish

# Security-sensitive mise settings must come from env because ~/.config/mise
# is symlinked into this repo and mise treats the real path as non-global.
set -gx MISE_TRUSTED_CONFIG_PATHS "$HOME/Developer:$HOME/Code:/workspaces"
set -gx MISE_GITHUB_CREDENTIAL_COMMAND "gh auth token"
set -gx MISE_PARANOID false
set -gx MISE_YES false

# mise/config.toml is also a project-config path. Ignore this repo's
# workstation manifest when a machine uses a separate global config, as the
# Raspberry Pi setup does.
begin
    set -l fish_config_dir (path resolve (status dirname))
    set -l dotfiles_dir (path dirname "$fish_config_dir")
    set -l repo_mise_config "$dotfiles_dir/mise/config.toml"
    set -l global_mise_config "$HOME/.config/mise/config.toml"

    if test -f "$repo_mise_config"; and test -f "$global_mise_config"
        if test (path resolve "$repo_mise_config") != (path resolve "$global_mise_config")
            set -l ignored_paths
            if set -q MISE_IGNORED_CONFIG_PATHS
                set ignored_paths (string split : -- "$MISE_IGNORED_CONFIG_PATHS")
            end
            if not contains -- "$repo_mise_config" $ignored_paths
                set -a ignored_paths "$repo_mise_config"
                set -gx MISE_IGNORED_CONFIG_PATHS (string join : $ignored_paths)
            end
        end
    end
end

# Initialize mise early so tools are available in all shells
if command -q mise
    # Avoid mise's default prompt hook; update once on startup and again only after cd.
    mise activate fish --no-hook-env | source
    mise hook-env -s fish | source

    function __mise_cd_hook --on-variable PWD --description 'Update mise environment when changing directories'
        mise hook-env -s fish | source
    end
end

# sudoedit may receive sudo's restricted PATH, so resolve the user-managed
# Neovim after mise has added its shims.
if command -q nvim
    set -gx SUDO_EDITOR (command -s nvim)
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
