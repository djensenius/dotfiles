#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/herdr-cli-update-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT

export TMPDIR="$TEST_ROOT/tmp"
export TEST_EXPECTED_MANAGERS=pip
mkdir -p "$TMPDIR/tmux-outdated-packages"

STATUS_HELPER="$TEST_ROOT/status-helper.sh"
cat >"$STATUS_HELPER" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
    --expected-managers)
        if [ -n "${TEST_EXPECTED_MANAGERS:-}" ]; then
            printf '%s\n' "$TEST_EXPECTED_MANAGERS"
        fi
        ;;
    --cache-ready | --wait-poller)
        exit 0
        ;;
    *)
        exit 2
        ;;
esac
EOF
chmod +x "$STATUS_HELPER"
export HERDR_STATUS_HELPER="$STATUS_HELPER"

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PATH=/usr/bin:/bin "$SCRIPT_DIR/../scripts/herdr-status-report.sh" \
    --expected-managers >/dev/null

export HERDR_STATUS_MAX_AGE=60
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../scripts/herdr-status-report.sh"
expected_package_managers() { printf '%s\n' pip; }

OUTDATED_CACHE="$TMPDIR/tmux-outdated-packages"
COMPLETE_FILE="$OUTDATED_CACHE/complete"
# shellcheck disable=SC2034 # Consumed by the sourced status helper.
CHECKING_FILE="$OUTDATED_CACHE/checking"
refresh_marker="$OUTDATED_CACHE/test-refresh"
old_time=202001010000
marker_time=202101010000
new_time=202201010000
complete_time=202301010000

printf '1\n' >"$OUTDATED_CACHE/pip.count"
printf 'package\n' >"$OUTDATED_CACHE/pip.list"
touch -t "$old_time" "$OUTDATED_CACHE/pip.count"
printf 'generation-current-1\n' >"$COMPLETE_FILE"
if package_cache_is_ready; then
    printf '%s\n' 'stale count file was accepted' >&2
    exit 1
fi

touch "$OUTDATED_CACHE/pip.count"
touch -t "$old_time" "$OUTDATED_CACHE/pip.list"
printf 'generation-current-2\n' >"$COMPLETE_FILE"
if package_cache_is_ready; then
    printf '%s\n' 'stale list file was accepted' >&2
    exit 1
fi

touch "$OUTDATED_CACHE/pip.count" "$OUTDATED_CACHE/pip.list"
printf 'generation-current-3\n' >"$COMPLETE_FILE"
package_cache_is_ready

touch -t "$marker_time" "$refresh_marker"
touch -t "$old_time" "$OUTDATED_CACHE/pip.count"
touch -t "$new_time" "$OUTDATED_CACHE/pip.list"
touch -t "$complete_time" "$COMPLETE_FILE"
if package_cache_is_ready "$refresh_marker"; then
    printf '%s\n' 'count file predating refresh was accepted' >&2
    exit 1
fi

touch -t "$new_time" "$OUTDATED_CACHE/pip.count"
touch -t "$old_time" "$OUTDATED_CACHE/pip.list"
if package_cache_is_ready "$refresh_marker"; then
    printf '%s\n' 'list file predating refresh was accepted' >&2
    exit 1
fi

touch -t "$new_time" "$OUTDATED_CACHE/pip.list"
package_cache_is_ready "$refresh_marker"
rm -f "$refresh_marker"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../scripts/herdr-cli-update.sh"

printf '1\n' >"$LIVE_CACHE_DIR/pip.count"
printf 'old-package\n' >"$LIVE_CACHE_DIR/pip.list"
: >"$LIVE_CACHE_DIR/complete"
if cache_generation_token >/dev/null; then
    printf '%s\n' 'empty complete generation was accepted' >&2
    exit 1
fi
printf 'generation-1\n' >"$LIVE_CACHE_DIR/complete"

copy_attempt=0
copy_cache_file() {
    cp "$1" "$2"
    if [ "$copy_attempt" -eq 0 ] && [ "$1" = "$LIVE_CACHE_DIR/pip.count" ]; then
        copy_attempt=1
        printf '2\n' >"$LIVE_CACHE_DIR/pip.count"
        printf 'new-package\n' >"$LIVE_CACHE_DIR/pip.list"
        printf 'generation-2\n' >"$LIVE_CACHE_DIR/.complete.next"
        mv "$LIVE_CACHE_DIR/.complete.next" "$LIVE_CACHE_DIR/complete"
    fi
}

load_expected_managers
snapshot_cache

[ "$(read_count pip.count)" = '2' ]
[ "$(cat "$CACHE_DIR/pip.list")" = 'new-package' ]

printf '3\n' >"$LIVE_CACHE_DIR/pip.count"
printf 'later-package\n' >"$LIVE_CACHE_DIR/pip.list"
[ "$(read_count pip.count)" = '2' ]
[ "$(cat "$CACHE_DIR/pip.list")" = 'new-package' ]

cleanup_snapshot
export TEST_EXPECTED_MANAGERS=''
rm -f "$LIVE_CACHE_DIR/complete" "$LIVE_CACHE_DIR/pip.count" "$LIVE_CACHE_DIR/pip.list"
load_expected_managers
snapshot_cache
# shellcheck disable=SC2154
[ "${#expected_manager_ids[@]}" -eq 0 ]
[ -d "$CACHE_DIR" ]

printf '%s\n' 'Herdr CLI cache snapshot tests passed'
