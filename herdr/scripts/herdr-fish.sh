#!/bin/sh
set -eu

fish_path=$(command -v fish) || {
    echo "herdr-fish: fish is not available in PATH" >&2
    exit 127
}

# Login state encoded in the wrapper's argv[0] is lost across the shebang.
if [ "$(uname -s)" = "Darwin" ]; then
    exec env fish_features=no-query-term "$fish_path" --login "$@"
fi

exec env fish_features=no-query-term "$fish_path" "$@"
