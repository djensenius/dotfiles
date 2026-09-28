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

LAUNCH_POLLER="$TEST_ROOT/launch-poller.sh"
cat >"$LAUNCH_POLLER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' launch-agent-poller
EOF
chmod +x "$LAUNCH_POLLER"
launch_output=$(XPC_SERVICE_NAME=dev.djensenius.herdr-status \
    HERDR_STATUS_POLLER="$LAUNCH_POLLER" \
    "$SCRIPT_DIR/../scripts/herdr-status-report.sh")
[ "$launch_output" = launch-agent-poller ]

export HERDR_STATUS_MAX_AGE=60
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../scripts/herdr-status-report.sh"

manager_probe_bin="$TEST_ROOT/manager-probe-bin"
mkdir -p "$manager_probe_bin" "$TEST_ROOT/pi-agent/npm"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$manager_probe_bin/pi"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$manager_probe_bin/npm"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$manager_probe_bin/node"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$manager_probe_bin/herdr"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$manager_probe_bin/git"
chmod +x "$manager_probe_bin"/*
old_path=$PATH
export PI_CODING_AGENT_DIR="$TEST_ROOT/pi-agent"
PI_AGENT_DIR="$PI_CODING_AGENT_DIR"
# shellcheck disable=SC2034 # Consumed by expected_package_managers from the sourced status helper.
PI_NPM_PREFIX="$PI_AGENT_DIR/npm"
PATH="$manager_probe_bin:/usr/bin:/bin"
OUTDATED_POLLER="$TEST_ROOT/old-poller.sh"
printf '%s\n' '#!/usr/bin/env bash' 'check_npm() { :; }' >"$OUTDATED_POLLER"
# shellcheck disable=SC2218 # expected_package_managers is sourced before the test-local override below.
if expected_package_managers | grep -Eq '^(pi|herdr)$'; then
    printf '%s\n' 'older poller without pi/herdr support required new cache files' >&2
    exit 1
fi
printf '%s\n' '#!/usr/bin/env bash' 'check_pi() { :; }' 'check_herdr() { :; }' >"$OUTDATED_POLLER"
# shellcheck disable=SC2218 # expected_package_managers is sourced before the test-local override below.
manager_probe_output=$(expected_package_managers)
grep -q '^pi$' <<<"$manager_probe_output"
grep -q '^herdr$' <<<"$manager_probe_output"
grep_path=$(command -v grep)
no_node_bin="$TEST_ROOT/no-node-bin"
mkdir -p "$no_node_bin"
cp "$manager_probe_bin/pi" "$manager_probe_bin/npm" "$manager_probe_bin/herdr" "$manager_probe_bin/git" "$no_node_bin/"
ln -s "$grep_path" "$no_node_bin/grep"
PATH="$no_node_bin"
manager_probe_output=$(expected_package_managers)
if grep -q '^pi$' <<<"$manager_probe_output"; then
    printf '%s\n' 'pi was expected without node on PATH' >&2
    exit 1
fi
PATH="$manager_probe_bin:/usr/bin:/bin"
rmdir "$PI_NPM_PREFIX"
manager_probe_output=$(expected_package_managers)
if grep -q '^pi$' <<<"$manager_probe_output"; then
    printf '%s\n' 'pi was expected without the Pi npm prefix directory' >&2
    exit 1
fi
mkdir -p "$PI_NPM_PREFIX"
no_git_bin="$TEST_ROOT/no-git-bin"
mkdir -p "$no_git_bin"
cp "$manager_probe_bin/pi" "$manager_probe_bin/npm" "$manager_probe_bin/node" "$manager_probe_bin/herdr" "$no_git_bin/"
ln -s "$grep_path" "$no_git_bin/grep"
PATH="$no_git_bin"
manager_probe_output=$(expected_package_managers)
if grep -q '^herdr$' <<<"$manager_probe_output"; then
    printf '%s\n' 'herdr was expected without git on PATH' >&2
    exit 1
fi
PATH=$old_path

expected_package_managers() { printf '%s\n' pip pi herdr; }

OUTDATED_CACHE="$TMPDIR/tmux-outdated-packages"
COMPLETE_FILE="$OUTDATED_CACHE/complete"
# shellcheck disable=SC2034 # Consumed by the sourced status helper.
CHECKING_FILE="$OUTDATED_CACHE/checking"
REFRESH_REQUEST_FILE="$OUTDATED_CACHE/refresh-request"
REFRESH_COMPLETE_FILE="$OUTDATED_CACHE/refresh-complete"
refresh_marker="$OUTDATED_CACHE/test-refresh"
old_time=202001010000
marker_time=202101010000
new_time=202201010000
complete_time=202301010000

printf 'legacy-generation\n' >"$COMPLETE_FILE"
if complete_generation_token >/dev/null; then
    printf '%s\n' 'legacy status generation was accepted' >&2
    exit 1
fi

printf '1\n' >"$OUTDATED_CACHE/pip.count"
printf 'package\n' >"$OUTDATED_CACHE/pip.list"
touch -t "$old_time" "$OUTDATED_CACHE/pip.count"
printf 'v2:generation-current-1\n' >"$COMPLETE_FILE"
if package_cache_is_ready; then
    printf '%s\n' 'stale count file was accepted' >&2
    exit 1
fi

touch "$OUTDATED_CACHE/pip.count"
touch -t "$old_time" "$OUTDATED_CACHE/pip.list"
printf 'v2:generation-current-2\n' >"$COMPLETE_FILE"
if package_cache_is_ready; then
    printf '%s\n' 'stale list file was accepted' >&2
    exit 1
fi

touch "$OUTDATED_CACHE/pip.count" "$OUTDATED_CACHE/pip.list"
printf 'v2:generation-current-3\n' >"$COMPLETE_FILE"
package_cache_is_ready

printf 'pending-refresh\n' >"$REFRESH_REQUEST_FILE"
rm -f "$REFRESH_COMPLETE_FILE"
if package_cache_is_ready; then
    printf '%s\n' 'cache was ready with an unacknowledged refresh' >&2
    exit 1
fi

refresh_signal_count=0
ensure_outdated_poller() { :; }
request_outdated_poller_refresh() {
    refresh_signal_count=$((refresh_signal_count + 1))
    printf '1\n' >"$OUTDATED_CACHE/pip.count"
    printf 'package\n' >"$OUTDATED_CACHE/pip.list"
    printf 'v2:generation-after-refresh\n' >"$COMPLETE_FILE"
    touch -t 202501010000 \
        "$OUTDATED_CACHE/pip.count" \
        "$OUTDATED_CACHE/pip.list" \
        "$COMPLETE_FILE"
    touch -t 202601010000 "$REFRESH_COMPLETE_FILE"
}
touch -t 202401010000 "$REFRESH_REQUEST_FILE"
wait_for_outdated_poller
[ "$refresh_signal_count" -eq 1 ]
if refresh_request_is_pending; then
    printf '%s\n' 'acknowledged refresh remained pending' >&2
    exit 1
fi

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
printf 'legacy-generation\n' >"$LIVE_CACHE_DIR/complete"
if cache_generation_token >/dev/null; then
    printf '%s\n' 'legacy updater generation was accepted' >&2
    exit 1
fi
printf 'v2:generation-1\n' >"$LIVE_CACHE_DIR/complete"

copy_attempt=0
copy_cache_file() {
    cp "$1" "$2"
    if [ "$copy_attempt" -eq 0 ] && [ "$1" = "$LIVE_CACHE_DIR/pip.count" ]; then
        copy_attempt=1
        printf '2\n' >"$LIVE_CACHE_DIR/pip.count"
        printf 'new-package\n' >"$LIVE_CACHE_DIR/pip.list"
        printf 'v2:generation-2\n' >"$LIVE_CACHE_DIR/.complete.next"
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
export TEST_EXPECTED_MANAGERS=$'pip\npi\nherdr'
rm -f \
    "$LIVE_CACHE_DIR/pi.count" \
    "$LIVE_CACHE_DIR/pi.list" \
    "$LIVE_CACHE_DIR/herdr.count" \
    "$LIVE_CACHE_DIR/herdr.list"
printf '4\n' >"$LIVE_CACHE_DIR/pip.count"
printf 'optional-missing-package\n' >"$LIVE_CACHE_DIR/pip.list"
printf 'v2:generation-optional-missing\n' >"$LIVE_CACHE_DIR/complete"
load_expected_managers
snapshot_cache
[ "$(read_count pip.count)" = '4' ]
[ ! -e "$CACHE_DIR/pi.count" ]
[ ! -e "$CACHE_DIR/herdr.count" ]

cleanup_snapshot
printf '1\n' >"$LIVE_CACHE_DIR/pi.count"
printf 'pi-web-access 0.32.0 -> 0.33.0\n' >"$LIVE_CACHE_DIR/pi.list"
printf '2\n' >"$LIVE_CACHE_DIR/herdr.count"
printf '%s\n' \
    'owner/old-plugin aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa -> cccccccccccccccccccccccccccccccccccccccc' \
    'owner/new-plugin dddddddddddddddddddddddddddddddddddddddd -> eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' \
    >"$LIVE_CACHE_DIR/herdr.list"
printf 'v2:generation-optional-present\n' >"$LIVE_CACHE_DIR/complete"
load_expected_managers
snapshot_cache
# shellcheck disable=SC2034 # Reset arrays consumed by add_manager/draw_screen from the sourced updater.
manager_ids=()
# shellcheck disable=SC2034 # Reset arrays consumed by add_manager/draw_screen from the sourced updater.
manager_names=()
# shellcheck disable=SC2034 # Reset arrays consumed by add_manager/draw_screen from the sourced updater.
manager_counts=()
# shellcheck disable=SC2034 # Reset arrays consumed by add_manager/draw_screen from the sourced updater.
manager_commands=()
# shellcheck disable=SC2034 # Reset arrays consumed by add_manager/draw_screen from the sourced updater.
manager_lists=()
# shellcheck disable=SC2034 # Consumed by draw_screen from the sourced updater.
cache_initialized=1
add_manager pi "Pi" pi.count "pi update --extensions" pi.list
add_manager herdr "Herdr" herdr.count "herdr plugin install <plugin> --yes" herdr.list
draw_output=$(draw_screen)
grep -q 'Pi' <<<"$draw_output"
grep -q 'pi-web-access 0.32.0 -> 0.33.0' <<<"$draw_output"
grep -q 'Herdr' <<<"$draw_output"
grep -q 'owner/new-plugin' <<<"$draw_output"

cleanup_snapshot
export TEST_EXPECTED_MANAGERS=''
rm -f \
    "$LIVE_CACHE_DIR/complete" \
    "$LIVE_CACHE_DIR/pip.count" \
    "$LIVE_CACHE_DIR/pip.list" \
    "$REFRESH_REQUEST_FILE" \
    "$REFRESH_COMPLETE_FILE"
load_expected_managers
snapshot_cache
# shellcheck disable=SC2154
[ "${#expected_manager_ids[@]}" -eq 0 ]
[ -d "$CACHE_DIR" ]

upgrade_bin="$TEST_ROOT/upgrade-bin"
upgrade_log="$TEST_ROOT/upgrade.log"
mkdir -p "$upgrade_bin"
cat >"$upgrade_bin/pi" <<'EOF'
#!/usr/bin/env bash
printf 'pi %s\n' "$*" >>"$UPGRADE_LOG"
EOF
cat >"$upgrade_bin/herdr" <<'EOF'
#!/usr/bin/env bash
printf 'herdr %s\n' "$*" >>"$UPGRADE_LOG"
cat >/dev/null
case "${3:-}" in
    owner/fail-plugin) exit 1 ;;
esac
EOF
chmod +x "$upgrade_bin"/*
PATH="$upgrade_bin:/usr/bin:/bin"
export UPGRADE_LOG="$upgrade_log"
rm -f "$CACHE_DIR/herdr.list"
if herdr_update_outdated_plugins 2>/dev/null; then
    printf '%s\n' 'missing Herdr plugin list was accepted' >&2
    exit 1
fi
: >"$CACHE_DIR/herdr.list"
if herdr_update_outdated_plugins 2>/dev/null; then
    printf '%s\n' 'empty Herdr plugin list was accepted' >&2
    exit 1
fi
printf '%s\n' \
    'owner/old-plugin aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa -> cccccccccccccccccccccccccccccccccccccccc' \
    'bad;name aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa -> cccccccccccccccccccccccccccccccccccccccc' \
    '../escape aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa -> cccccccccccccccccccccccccccccccccccccccc' \
    'owner/.. aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa -> cccccccccccccccccccccccccccccccccccccccc' \
    '-flag/repo aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa -> cccccccccccccccccccccccccccccccccccccccc' \
    'owner/fail-plugin dddddddddddddddddddddddddddddddddddddddd -> eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' \
    'owner/new-plugin ffffffffffffffffffffffffffffffffffffffff -> 1111111111111111111111111111111111111111' \
    >"$CACHE_DIR/herdr.list"
run_upgrade pi
if run_upgrade herdr; then
    printf '%s\n' 'failing Herdr plugin reinstall was accepted' >&2
    exit 1
fi
grep -q '^pi update --extensions$' "$upgrade_log"
grep -q '^herdr plugin install owner/old-plugin --yes$' "$upgrade_log"
grep -q '^herdr plugin install owner/fail-plugin --yes$' "$upgrade_log"
grep -q '^herdr plugin install owner/new-plugin --yes$' "$upgrade_log"
if grep -q -e 'bad;name' -e 'install \.\./escape' -e 'install owner/\.\. ' -e 'install -flag' "$upgrade_log"; then
    printf '%s\n' 'invalid Herdr plugin name was installed' >&2
    exit 1
fi

# The launchd poller must see the same Pi agent directory as this helper.
(
    HOME="$TEST_ROOT/launch-home"
    mkdir -p "$HOME/Library/LaunchAgents"
    : >"$HOME/Library/LaunchAgents/$LAUNCH_LABEL.plist"
    PI_AGENT_DIR="$TEST_ROOT/custom-pi-agent"
    launchctl_log="$TEST_ROOT/launchctl.log"
    : >"$launchctl_log"
    # shellcheck disable=SC2329 # Called by start_poller_launch_agent from the sourced helper.
    launchctl() {
        printf '%s\n' "$*" >>"$launchctl_log"
        [ "$1" != print ]
    }
    start_poller_launch_agent
    grep -Fxq "setenv PI_CODING_AGENT_DIR $TEST_ROOT/custom-pi-agent" "$launchctl_log" || {
        printf '%s\n' 'launch agent did not receive the resolved Pi agent directory' >&2
        exit 1
    }
    grep -q '^kickstart -k ' "$launchctl_log"
)

printf '%s\n' 'Herdr CLI cache snapshot tests passed'
