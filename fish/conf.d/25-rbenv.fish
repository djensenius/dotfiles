# rbenv only outside Codespaces (matches your original logic)
if not test -d /workspaces
    status is-interactive; and command -q rbenv; and rbenv init - fish | source
end
