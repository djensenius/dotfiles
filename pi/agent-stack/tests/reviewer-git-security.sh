#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../.." && pwd)"
EXTENSION="$REPO_ROOT/pi/agent-stack/extensions/reviewer-git.ts"
TEST_EXTENSION="$DIR/reviewer-git-security.ts"
PI_BIN="${PI_BIN:-$(mise -C "$REPO_ROOT" which pi)}"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/reviewer-git-security.XXXXXX")"
cleanup() {
  rm -rf -- "$tmp"
}
trap cleanup EXIT

repo="$tmp/repo"
decoy="$tmp/decoy"
home="$tmp/home"
helpers="$tmp/helpers"
markers="$tmp/markers"
mkdir -p "$repo" "$decoy" "$home" "$helpers" "$markers" "$tmp/pi-agent"

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
  textconv; do
  cat > "$helpers/$name" <<'HELPER'
#!/usr/bin/env bash
set -euo pipefail

name="$(basename "$0")"
: > "$REVIEW_GIT_MARKER_DIR/$name"
case "$name" in
  filter-clean|textconv|*-pager) cat ;;
esac
HELPER
  chmod 755 "$helpers/$name"
done

git -C "$repo" init -q
git -C "$repo" config user.name "Reviewer Git Test"
git -C "$repo" config user.email "reviewer-git@example.invalid"
printf '*.txt filter=evil diff=evil\n' > "$repo/.gitattributes"
printf 'before\n' > "$repo/tracked.txt"
git -C "$repo" add .gitattributes tracked.txt
git -C "$repo" commit -q -m "Base"
base="$(git -C "$repo" rev-parse HEAD)"
printf 'after\n' > "$repo/tracked.txt"
git -C "$repo" add tracked.txt
git -C "$repo" commit -q -m "Target"
commit="$(git -C "$repo" rev-parse HEAD)"

git -C "$decoy" init -q
git -C "$decoy" config user.name "Reviewer Git Decoy"
git -C "$decoy" config user.email "reviewer-git-decoy@example.invalid"
printf 'decoy\n' > "$decoy/decoy.txt"
git -C "$decoy" add decoy.txt
git -C "$decoy" commit -q -m "Decoy"

git -C "$repo" config filter.evil.clean "$helpers/filter-clean"
git -C "$repo" config filter.evil.process "$helpers/filter-process"
git -C "$repo" config filter.evil.required true
git -C "$repo" config diff.external "$helpers/diff-external"
git -C "$repo" config diff.evil.textconv "$helpers/textconv"
git -C "$repo" config core.pager "$helpers/core-pager"
git -C "$repo" config pager.show "$helpers/show-pager"
git -C "$repo" config pager.diff "$helpers/diff-pager"
git -C "$repo" config pager.log "$helpers/log-pager"
git -C "$repo" config core.fsmonitor "$helpers/fsmonitor"
git -C "$repo" config credential.helper "!$helpers/credential-helper"
git -C "$repo" config core.askPass "$helpers/askpass"
printf 'dirty worktree\n' > "$repo/tracked.txt"

git config --file "$home/.gitconfig" diff.external "$helpers/global-diff"
git config --file "$home/.gitconfig" core.pager "$helpers/global-pager"
git config --file "$home/.gitconfig" core.fsmonitor "$helpers/global-fsmonitor"
git config --file "$home/.gitconfig" credential.helper "!$helpers/credential-helper"

system_config="$tmp/system.gitconfig"
git config --file "$system_config" diff.external "$helpers/system-diff"
git config --file "$system_config" core.pager "$helpers/system-pager"
git config --file "$system_config" core.fsmonitor "$helpers/system-fsmonitor"
git config --file "$system_config" credential.helper "!$helpers/credential-helper"

output="$tmp/pi-output.jsonl"
(
  cd "$repo"
  env \
    HOME="$home" \
    PI_CODING_AGENT_DIR="$tmp/pi-agent" \
    REVIEW_GIT_MARKER_DIR="$markers" \
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
      -p "/review-git-security-test $base $commit"
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
  and .completed == ["rev-parse", "show", "diff", "log"]
  and .statusRejected == true
' >/dev/null

marker_files="$(find "$markers" -type f -print)"
if [ -n "$marker_files" ]; then
  printf 'Unexpected Git helper side effects:\n' >&2
  printf '%s\n' "$marker_files" >&2
  exit 1
fi

printf 'reviewer-git security test passed: %s\n' "$summary"
printf 'reviewer-git helper side effects: none\n'
