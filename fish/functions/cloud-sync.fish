function cloud-sync --description "Sync selected ~/Documents folders to OneDrive / Google Drive"
    set -l script "$HOME/Developer/dotfiles/scripts/onedrive_sync.py"
    if not test -f "$script"
        echo "cloud-sync: script not found at $script" >&2
        return 1
    end
    python3 "$script" $argv
end
