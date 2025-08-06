# Codespaces/Devcontainer adjustments
if test -d /workspaces
    # npm global prefix PATH (fixed to fish command substitution)
    set -l npm_prefix (npm config get prefix 2>/dev/null)
    if test -n "$npm_prefix"
        fish_add_path -g $npm_prefix $npm_prefix/bin
    end

    # fzf binaries in Codespaces
    if test -d ~/.fzf/bin
        fish_add_path -g ~/.fzf/bin
    end
end

# Custom container marker for Neovim path
if test -e /etc/dfj-container
    fish_add_path -g /opt/nvim-linux64/bin
end
