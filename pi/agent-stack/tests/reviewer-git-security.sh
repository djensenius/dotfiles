#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../.." && pwd)"
INSTALLER="$DIR/../install.sh"
EXTENSION="$REPO_ROOT/pi/agent-stack/extensions/reviewer-git.ts"
TEST_EXTENSION="$DIR/reviewer-git-security.ts"
GIT_BIN="$(command -v git)"
PI_BIN="${PI_BIN:-$(mise -C "$REPO_ROOT" which pi)}"

bash -c 'source "$1"; require_git_version' bash "$INSTALLER" >/dev/null

tmp="$(mktemp -d "${TMPDIR:-/tmp}/reviewer-git-security.XXXXXX")"
cleanup() {
  rm -rf -- "$tmp"
}
trap cleanup EXIT

repo="$tmp/repo "
decoy="$tmp/decoy"
origin="$tmp/origin.git"
partial="$tmp/partial"
nested="$repo/modules/nested"
home="$tmp/home"
helpers="$tmp/helpers"
markers="$tmp/markers"
control_markers="$tmp/control-markers"
invocation_log="$tmp/git-invocations.log"
expected_diff="$tmp/expected-diff.txt"
expected_submodule_show="$tmp/expected-submodule-show.txt"
expected_submodule_diff="$tmp/expected-submodule-diff.txt"
mkdir -p "$repo" "$decoy" "$home" "$helpers" "$markers" "$control_markers" "$tmp/pi-agent"
: > "$invocation_log"

for name in \
  askpass \
  config-count-diff \
  core-pager \
  credential-helper \
  diff-external \
  diff-pager \
  env-askpass \
  env-diff \
  env-pager \
  env-ssh \
  filter-clean \
  filter-process \
  fsmonitor \
  global-diff \
  global-fsmonitor \
  global-pager \
  log-pager \
  show-pager \
  system-diff \
  system-fsmonitor \
  system-pager \
  textconv \
  uploadpack; do
  cat > "$helpers/$name" <<'HELPER'
#!/usr/bin/env bash
set -euo pipefail

name="$(basename "$0")"
: > "$REVIEW_GIT_MARKER_DIR/$name"
case "$name" in
  filter-clean|textconv|*-pager) cat ;;
  uploadpack) exit 97 ;;
esac
HELPER
  chmod 755 "$helpers/$name"
done

cat > "$helpers/git" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

has_no_lazy_fetch=false
for argument in "$@"; do
  if [ "$argument" = "--no-lazy-fetch" ]; then
    has_no_lazy_fetch=true
    break
  fi
done
if ! $has_no_lazy_fetch; then
  : > "$REVIEW_GIT_MARKER_DIR/missing-no-lazy-fetch"
fi

printf '%s\n' "$*" >> "$REVIEW_GIT_INVOCATION_LOG"
case "${REVIEW_GIT_TEST_MODE:-}" in
  stderr)
    printf '%09000d' 0 >&2
    exit 91
    ;;
  timeout)
    exec sleep 30
    ;;
esac

exec "$REVIEW_GIT_REAL_GIT" "$@"
WRAPPER
chmod 755 "$helpers/git"

"$GIT_BIN" init -q --object-format=sha1 "$repo"
"$GIT_BIN" -C "$repo" config user.name "Reviewer Git Test"
"$GIT_BIN" -C "$repo" config user.email "reviewer-git@example.invalid"
mkdir -p "$nested"
"$GIT_BIN" init -q --object-format=sha1 "$nested"
"$GIT_BIN" -C "$nested" config user.name "Reviewer Git Nested"
"$GIT_BIN" -C "$nested" config user.email "reviewer-git-nested@example.invalid"
printf 'nested before\n' > "$nested/nested.txt"
"$GIT_BIN" -C "$nested" add nested.txt
"$GIT_BIN" -C "$nested" commit -q -m "Nested base"
submodule_old="$("$GIT_BIN" -C "$nested" rev-parse HEAD)"

printf '*.txt filter=evil diff=evil\nforced-text.bin -diff\n' > "$repo/.gitattributes"
printf 'before\n' > "$repo/tracked.txt"
printf 'forced text before\n' > "$repo/forced-text.bin"
awk 'BEGIN {
  for (i = 0; i < 700; i++) {
    printf "before-%05d cafe-\303\251 emoji-\360\237\230\200 alpha beta gamma delta\n", i
  }
}' > "$repo/large.txt"
"$GIT_BIN" -C "$repo" add .gitattributes tracked.txt forced-text.bin large.txt
"$GIT_BIN" -C "$repo" update-index --add --cacheinfo "160000,$submodule_old,modules/nested"
"$GIT_BIN" -C "$repo" commit -q -m "Base"
base="$("$GIT_BIN" -C "$repo" rev-parse HEAD)"

printf 'nested after\n' > "$nested/nested.txt"
"$GIT_BIN" -C "$nested" add nested.txt
"$GIT_BIN" -C "$nested" commit -q -m "Nested target"
submodule_new="$("$GIT_BIN" -C "$nested" rev-parse HEAD)"

printf 'after\n' > "$repo/tracked.txt"
printf 'forced text after\n' > "$repo/forced-text.bin"
awk 'BEGIN {
  for (i = 0; i < 700; i++) {
    printf "after-%05d cafe-\303\251 emoji-\360\237\230\200 alpha beta gamma delta\n", i
  }
}' > "$repo/large.txt"
"$GIT_BIN" -C "$repo" add tracked.txt forced-text.bin large.txt
"$GIT_BIN" -C "$repo" update-index --cacheinfo "160000,$submodule_new,modules/nested"
"$GIT_BIN" -C "$repo" commit -q -m "Target"
commit="$("$GIT_BIN" -C "$repo" rev-parse HEAD)"
short_ref="${commit:0:12}"
"$GIT_BIN" -C "$repo" update-ref "refs/heads/$short_ref" "$base"
"$GIT_BIN" -C "$repo" config core.bigFileThreshold 1

review_git_expected() {
  env \
    GIT_CONFIG_GLOBAL=/dev/null \
    GIT_CONFIG_NOSYSTEM=1 \
    GIT_NO_LAZY_FETCH=1 \
    GIT_OPTIONAL_LOCKS=0 \
    GIT_PAGER=cat \
    LC_ALL=C \
    NO_COLOR=1 \
    PAGER=cat \
    "$GIT_BIN" \
      --no-pager \
      --no-lazy-fetch \
      --no-replace-objects \
      --literal-pathspecs \
      -c color.ui=false \
      -c core.fsmonitor=false \
      -c core.pager=cat \
      -c core.untrackedCache=false \
      -c log.showSignature=false \
      -c submodule.recurse=false \
      -C "$repo" \
      "$@"
}

review_git_expected \
  diff \
  --no-color \
  --no-ext-diff \
  --no-textconv \
  --text \
  --ignore-submodules=dirty \
  --submodule=short \
  --stat \
  --patch \
  "$base" \
  "$commit" \
  -- \
  large.txt > "$expected_diff"

review_git_expected \
  show \
  --no-color \
  --no-ext-diff \
  --no-textconv \
  --text \
  --ignore-submodules=dirty \
  --submodule=short \
  --format=fuller \
  --stat \
  --patch \
  "$commit" \
  -- \
  modules/nested > "$expected_submodule_show"

review_git_expected \
  diff \
  --no-color \
  --no-ext-diff \
  --no-textconv \
  --text \
  --ignore-submodules=dirty \
  --submodule=short \
  --stat \
  --patch \
  "$base" \
  "$commit" \
  -- \
  modules/nested > "$expected_submodule_diff"

expected_bytes="$(wc -c < "$expected_diff" | tr -d '[:space:]')"
if [ "$expected_bytes" -le $((48 * 1024)) ]; then
  printf 'Expected pagination fixture to exceed 48 KiB, got %s bytes\n' "$expected_bytes" >&2
  exit 1
fi

for revision in "$base" "$commit"; do
  gitlink_mode="$("$GIT_BIN" -C "$repo" ls-tree "$revision" modules/nested | awk '{print $1}')"
  if [ "$gitlink_mode" != "160000" ]; then
    printf 'Expected mode 160000 gitlink at %s, got %s\n' "$revision" "$gitlink_mode" >&2
    exit 1
  fi
done

printf 'dirty nested worktree\n' >> "$nested/nested.txt"
printf 'untracked nested state\n' > "$nested/untracked.txt"
if [ -z "$("$GIT_BIN" -C "$nested" status --porcelain)" ]; then
  printf 'Nested repository did not become dirty\n' >&2
  exit 1
fi

"$GIT_BIN" init -q --bare --object-format=sha1 "$origin"
"$GIT_BIN" --git-dir="$origin" config uploadpack.allowFilter true
"$GIT_BIN" --git-dir="$origin" config uploadpack.allowAnySHA1InWant true
"$GIT_BIN" -C "$repo" remote add security-origin "file://$origin"
"$GIT_BIN" -C "$repo" push -q security-origin "$commit:refs/heads/main"
"$GIT_BIN" --git-dir="$origin" symbolic-ref HEAD refs/heads/main
"$GIT_BIN" clone -q --filter=blob:none --no-checkout "file://$origin" "$partial"
partial_commit="$("$GIT_BIN" -C "$partial" rev-parse HEAD)"
large_blob="$("$GIT_BIN" -C "$repo" rev-parse "$commit:large.txt")"
if "$GIT_BIN" --no-lazy-fetch -C "$partial" cat-file -e "$large_blob" 2>/dev/null; then
  printf 'Partial clone unexpectedly contains the large blob\n' >&2
  exit 1
fi
"$GIT_BIN" -C "$partial" config remote.origin.uploadpack "$helpers/uploadpack"
set +e
REVIEW_GIT_MARKER_DIR="$control_markers" GIT_NO_LAZY_FETCH=0 \
  "$GIT_BIN" -C "$partial" show "$partial_commit:large.txt" >/dev/null 2>&1
control_status=$?
set -e
if [ "$control_status" -eq 0 ] || [ ! -f "$control_markers/uploadpack" ]; then
  printf 'Partial-clone control did not invoke the configured uploadpack helper\n' >&2
  exit 1
fi

"$GIT_BIN" init -q --object-format=sha1 "$decoy"
"$GIT_BIN" -C "$decoy" config user.name "Reviewer Git Decoy"
"$GIT_BIN" -C "$decoy" config user.email "reviewer-git-decoy@example.invalid"
printf 'decoy\n' > "$decoy/decoy.txt"
"$GIT_BIN" -C "$decoy" add decoy.txt
"$GIT_BIN" -C "$decoy" commit -q -m "Decoy"

"$GIT_BIN" -C "$repo" config filter.evil.clean "$helpers/filter-clean"
"$GIT_BIN" -C "$repo" config filter.evil.process "$helpers/filter-process"
"$GIT_BIN" -C "$repo" config filter.evil.required true
"$GIT_BIN" -C "$repo" config diff.external "$helpers/diff-external"
"$GIT_BIN" -C "$repo" config diff.evil.textconv "$helpers/textconv"
"$GIT_BIN" -C "$repo" config core.pager "$helpers/core-pager"
"$GIT_BIN" -C "$repo" config pager.show "$helpers/show-pager"
"$GIT_BIN" -C "$repo" config pager.diff "$helpers/diff-pager"
"$GIT_BIN" -C "$repo" config pager.log "$helpers/log-pager"
"$GIT_BIN" -C "$repo" config core.fsmonitor "$helpers/fsmonitor"
"$GIT_BIN" -C "$repo" config credential.helper "!$helpers/credential-helper"
"$GIT_BIN" -C "$repo" config core.askPass "$helpers/askpass"
printf 'dirty worktree\n' > "$repo/tracked.txt"

"$GIT_BIN" config --file "$home/.gitconfig" diff.external "$helpers/global-diff"
"$GIT_BIN" config --file "$home/.gitconfig" core.pager "$helpers/global-pager"
"$GIT_BIN" config --file "$home/.gitconfig" core.bigFileThreshold 1
"$GIT_BIN" config --file "$home/.gitconfig" core.fsmonitor "$helpers/global-fsmonitor"
"$GIT_BIN" config --file "$home/.gitconfig" credential.helper "!$helpers/credential-helper"

system_config="$tmp/system.gitconfig"
"$GIT_BIN" config --file "$system_config" diff.external "$helpers/system-diff"
"$GIT_BIN" config --file "$system_config" core.pager "$helpers/system-pager"
"$GIT_BIN" config --file "$system_config" core.bigFileThreshold 1
"$GIT_BIN" config --file "$system_config" core.fsmonitor "$helpers/system-fsmonitor"
"$GIT_BIN" config --file "$system_config" credential.helper "!$helpers/credential-helper"

output="$tmp/pi-output.jsonl"
(
  cd "$repo"
  env \
    HOME="$home" \
    PATH="$helpers:$PATH" \
    PI_CODING_AGENT_DIR="$tmp/pi-agent" \
    REVIEW_GIT_EXPECTED_DIFF_FILE="$expected_diff" \
    REVIEW_GIT_EXPECTED_SUBMODULE_DIFF_FILE="$expected_submodule_diff" \
    REVIEW_GIT_EXPECTED_SUBMODULE_SHOW_FILE="$expected_submodule_show" \
    REVIEW_GIT_INVOCATION_LOG="$invocation_log" \
    REVIEW_GIT_MARKER_DIR="$markers" \
    REVIEW_GIT_PARTIAL_REPO="$partial" \
    REVIEW_GIT_REAL_GIT="$GIT_BIN" \
    REVIEW_GIT_SUBMODULE_NEW="$submodule_new" \
    REVIEW_GIT_SUBMODULE_OLD="$submodule_old" \
    GIT_ALTERNATE_OBJECT_DIRECTORIES="$decoy/.git/objects" \
    GIT_ASKPASS="$helpers/env-askpass" \
    GIT_CEILING_DIRECTORIES="/" \
    GIT_COMMON_DIR="$decoy/.git" \
    GIT_CONFIG_COUNT=4 \
    GIT_CONFIG_GLOBAL="$home/.gitconfig" \
    GIT_CONFIG_KEY_0=diff.external \
    GIT_CONFIG_KEY_1=core.pager \
    GIT_CONFIG_KEY_2=core.fsmonitor \
    GIT_CONFIG_KEY_3=credential.helper \
    GIT_CONFIG_NOSYSTEM=0 \
    GIT_CONFIG_PARAMETERS="'diff.external'='$helpers/config-count-diff'" \
    GIT_CONFIG_SYSTEM="$system_config" \
    GIT_CONFIG_VALUE_0="$helpers/config-count-diff" \
    GIT_CONFIG_VALUE_1="$helpers/env-pager" \
    GIT_CONFIG_VALUE_2="$helpers/fsmonitor" \
    GIT_CONFIG_VALUE_3="!$helpers/credential-helper" \
    GIT_DIR="$decoy/.git" \
    GIT_EXEC_PATH="$helpers" \
    GIT_EXTERNAL_DIFF="$helpers/env-diff" \
    GIT_INDEX_FILE="$tmp/hostile-index" \
    GIT_NO_LAZY_FETCH=0 \
    GIT_OBJECT_DIRECTORY="$decoy/.git/objects" \
    GIT_OPTIONAL_LOCKS=1 \
    GIT_PAGER="$helpers/env-pager" \
    GIT_SSH_COMMAND="$helpers/env-ssh" \
    GIT_TERMINAL_PROMPT=1 \
    GIT_TRACE="$markers/git-trace" \
    GIT_TRACE2_EVENT="$markers/git-trace2" \
    GIT_WORK_TREE="$decoy" \
    "$PI_BIN" \
      --no-session \
      --offline \
      --no-extensions \
      --extension "$EXTENSION" \
      --extension "$TEST_EXTENSION" \
      --no-builtin-tools \
      --no-skills \
      --no-prompt-templates \
      --no-themes \
      --no-context-files \
      --mode json \
      -p "/review-git-security-test $base $commit $short_ref $partial_commit"
) > "$output"

summary="$(
  jq -er '
    select(
      .type == "message_end"
      and .message.role == "custom"
      and .message.customType == "review-git-security-test"
    )
    | .message.content
  ' "$output" | tail -n 1
)"

printf '%s\n' "$summary" | jq -e '
  .ok == true
  and .operations == ["diff", "log", "rev-parse", "show"]
  and .fullShaSchema == true
  and .completed == ["rev-parse", "show", "log", "diff"]
  and .pagination.totalPages > 1
  and .pagination.stdoutBytes > 49152
  and .pagination.reconstructed == true
  and .pagination.outOfRangeRejected == true
  and .shortRefRejectedBeforeGit == true
  and .statusRejected == true
  and .revParseSinglePage == true
  and .forcedTextVisibility.show == true
  and .forcedTextVisibility.diff == true
  and .forcedTextVisibility.bigFileThreshold == true
  and .forcedTextVisibility.negativeDiffAttribute == true
  and .gitlinkVisibility.show == true
  and .gitlinkVisibility.diff == true
  and .gitlinkVisibility.mode == "160000"
  and .gitlinkVisibility.dirtyWorktreeIgnored == true
  and .lazyFetchBlocked == true
  and .cancellationRejected == true
  and .stderrTruncationRejected == true
  and .timeoutRejected == true
' >/dev/null

if [ ! -s "$invocation_log" ]; then
  printf 'review_git did not invoke Git through the test wrapper\n' >&2
  exit 1
fi

show_args=" show --no-color --no-ext-diff --no-textconv --text --ignore-submodules=dirty --submodule=short --format=fuller --stat --patch "
diff_args=" diff --no-color --no-ext-diff --no-textconv --text --ignore-submodules=dirty --submodule=short --stat --patch "
log_args=" log --no-color --no-decorate --no-ext-diff --no-textconv --ignore-submodules=all --date=iso-strict "
for expected_args in "$show_args" "$diff_args" "$log_args"; do
  if ! grep -F "$expected_args" "$invocation_log" >/dev/null; then
    printf 'Missing expected Git arguments: %s\n' "$expected_args" >&2
    exit 1
  fi
done

marker_files="$(find "$markers" -type f -print)"
if [ -n "$marker_files" ]; then
  printf 'Unexpected Git helper or lazy-fetch side effects:\n' >&2
  printf '%s\n' "$marker_files" >&2
  exit 1
fi

printf 'reviewer-git security test passed: %s\n' "$summary"
printf 'reviewer-git helper/lazy-fetch side effects: none\n'
