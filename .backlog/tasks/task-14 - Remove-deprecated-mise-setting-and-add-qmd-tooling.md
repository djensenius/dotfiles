---
id: TASK-14
title: Remove deprecated mise setting and add qmd tooling
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-10 03:37'
updated_date: '2026-10-10 03:47'
labels: []
dependencies: []
modified_files:
  - mise/config.toml
  - mise/config-test.toml
  - README.md
  - pi/agent-stack/install.sh
  - pi/agent-stack/tests/install-runtime.sh
type: chore
ordinal: 13000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
mise now warns that `plugin_autoupdate_last_check_duration` was never implemented and has no effect. The warning is emitted from the workstation mise configs. The Pi memory extension also reports that `memory_search` needs the qmd CLI, so the tool should be available through the managed toolchain instead of requiring a one-off manual install.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 No repository mise config contains `plugin_autoupdate_last_check_duration`.
- [x] #2 The managed workstation tool manifest includes qmd so `memory_search` prerequisites are installed with the dotfiles toolchain.
- [x] #3 Validation confirms the deprecated setting is gone and the edited TOML remains parseable.
- [ ] #4 The standalone Pi/Herdr agent-stack installer installs and verifies qmd through the repo's managed mise path, including a cheap qmd command, so pi-memory memory_search works without a separate manual qmd install.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect standalone agent-stack installer, root wrapper, and runtime test mocks for managed mise npm tool handling.
2. Update pi/agent-stack/install.sh so qmd/npm:@tobilu/qmd is installed and verified by the existing mise-managed toolchain path.
3. Add targeted install-runtime test coverage for the qmd mise install behavior and update minimal user-facing messaging/docs only if the installer output needs to name the tooling.
4. Validate targeted agent-stack runtime tests plus required mise/TOML/deprecated-setting checks, then finalize the task again.
5. Final polish after review: quote the mise binary lookup, verify qmd by running a managed qmd --version command, add a targeted runtime-test failure path for qmd verification, and re-run the requested validation before marking the task Done again.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented in mise/config.toml and mise/config-test.toml: removed plugin_autoupdate_last_check_duration and its obsolete explanatory comment block; added "npm:@tobilu/qmd" = "latest" to the npm package tools.
Validation passed:
- git grep -n "plugin_autoupdate_last_check_duration" -- "*.toml" produced no matches.
- git grep -n "npm:@tobilu/qmd" -- mise/config.toml mise/config-test.toml reported entries in both files.
- python3 tomllib parsed both edited TOML files and found npm:@tobilu/qmd="latest".
- tomllint mise/config.toml mise/config-test.toml passed.
- Project TOML lint command `for f in **/*.toml; do [ -f "$f" ] && tomllint "$f"; done` passed.

Fix round reopened after reviewer note and user clarification: standalone Pi/Herdr agent-stack installer must install qmd through mise, not raw npm.

Fix-round implementation after reviewer note/user clarification:
- Updated `pi/agent-stack/install.sh` to install `npm:@tobilu/qmd` in the unified mise install command with node/npm/pi/herdr, then verify the `qmd` shim with `mise -C "$REPO_ROOT" which qmd`.
- Updated `pi/agent-stack/tests/install-runtime.sh` mock expectations so runtime tests fail unless qmd is included in the mise install argument list and `which qmd` runs after install; added qmd stale/system runtime mocks to prove the script stays on the managed mise path.
- Added a minimal README note that the agent-stack installer installs `npm:@tobilu/qmd` for `pi-memory` memory_search.
- Source/docs commit: dd36a02758eac122c8aa59eb67d3ca880783030e.
Validation passed:
- `bash pi/agent-stack/tests/install-runtime.sh` -> `installer mise runtime tests passed`.
- `bash mac/tests/brewfile-mise-lint.sh` -> `ok Brewfiles do not overlap mise-owned tools`.
- `git grep -n "plugin_autoupdate_last_check_duration" -- "*.toml" || true` -> no output.
- python3 tomllib parsed `mise/config.toml` and `mise/config-test.toml`, confirming `npm:@tobilu/qmd=latest` in both.
- `tomllint mise/config.toml mise/config-test.toml` -> no output.
- `bash -n pi/agent-stack/install.sh pi/agent-stack/tests/install-runtime.sh` -> no output.
- `git diff --check` -> no output.
- qmd grep assertions showed `QMD_SOURCE`, the mise install command, `which qmd`, and install-runtime `install:node npm pi herdr $QMD_SOURCE` / `which:qmd` assertions.

Final polish started after reviewer APPROVE WITH NOTES: addressing qmd availability quoting, managed qmd command verification, targeted failure-path coverage, and explicit standalone installer acceptance criteria.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fix round for TASK-14 now makes the standalone Pi/Herdr agent-stack installer install npm:@tobilu/qmd through mise alongside node/npm/pi/herdr and verify qmd via mise which. Runtime tests now assert qmd is part of the mocked mise install flow and verified after install; README minimally documents qmd as the pi-memory memory_search dependency. Verified with install-runtime.sh, brewfile/mise lint, deprecated-setting grep, tomllib/tomllint checks for the mise manifests, bash -n, grep assertions, and git diff --check.
<!-- SECTION:FINAL_SUMMARY:END -->
