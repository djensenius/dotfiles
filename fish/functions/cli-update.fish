function cli-update --description 'Interactively update outdated CLI packages'
    set -l updater "$HOME/.config/herdr/scripts/herdr-cli-update.sh"

    if not test -x "$updater"
        echo "cli-update: updater not found at $updater" >&2
        return 127
    end

    command "$updater" $argv
end
