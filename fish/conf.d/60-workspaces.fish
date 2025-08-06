# Codespaces/workspaces-specific PATH fixes

if test -d /workspaces
    # 1) Vendored Node bins (e.g., /workspaces/github/vendor/node/node-vXX.../bin)
    for dir in /workspaces/*/vendor/node/*/bin
        if test -d $dir
            fish_add_path -g $dir
        end
    end

    # 2) npm global bin (only if npm exists)
    if command -q npm
        set -l npm_prefix (npm config get prefix 2>/dev/null)
        if test -n "$npm_prefix"; and test -d "$npm_prefix/bin"
            fish_add_path -g "$npm_prefix/bin"
        end
    end

    # 3) Ruby: expose rbenv "bin" locations without enabling shims
    for r in /root/.rbenv/bin /usr/local/share/rbenv/bin
        if test -d $r
            fish_add_path -g $r
        end
    end

    # 4) Go toolchains
    for g in /usr/local/go/bin /go/bin
        if test -d $g
            fish_add_path -g $g
        end
    end

    # 5) per-user fzf bin
    if test -d "$HOME/.fzf/bin"
        fish_add_path -g "$HOME/.fzf/bin"
    end

    # 6) Match parent PATH oddity if present
    if test -d /usr/local/share
        fish_add_path -g /usr/local/share
    end
end
