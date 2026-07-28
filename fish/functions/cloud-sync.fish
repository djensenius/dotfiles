function cloud-sync --description "Sync selected ~/Documents folders to OneDrive / Google Drive"
    # Resolve the checkout from this file's own location rather than assuming
    # ~/Developer/dotfiles: fish/ is symlinked into ~/.config, and the checkout
    # lives elsewhere on other machines (e.g. /workspaces/github in Codespaces).
    set -l here (realpath (status filename))
    set -l repo (path dirname (path dirname (path dirname $here)))
    set -l script "$repo/scripts/onedrive_sync.py"
    if not test -f "$script"
        echo "cloud-sync: script not found at $script" >&2
        return 1
    end
    python3 "$script" $argv
end
