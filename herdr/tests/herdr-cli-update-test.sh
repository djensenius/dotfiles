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
