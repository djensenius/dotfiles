---
id: TASK-14
title: Remove deprecated mise setting and add qmd tooling
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-10 03:37'
updated_date: '2026-10-10 03:41'
labels: []
dependencies: []
modified_files:
  - mise/config.toml
  - mise/config-test.toml
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
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect standalone agent-stack installer, root wrapper, and runtime test mocks for managed mise npm tool handling.\n2. Update pi/agent-stack/install.sh so qmd/npm:@tobilu/qmd is installed and verified by the existing mise-managed toolchain path.\n3. Add targeted install-runtime test coverage for the qmd mise install behavior and update minimal user-facing messaging/docs only if the installer output needs to name the tooling.\n4. Validate targeted agent-stack runtime tests plus required mise/TOML/deprecated-setting checks, then finalize the task again.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented in mise/config.toml and mise/config-test.toml: removed plugin_autoupdate_last_check_duration and its obsolete explanatory comment block; added "npm:@tobilu/qmd" = "latest" to the npm package tools.
Validation passed:
- git grep -n "plugin_autoupdate_last_check_duration" -- '*.toml' produced no matches.
- git grep -n 'npm:@tobilu/qmd' -- mise/config.toml mise/config-test.toml reported entries in both files.
- python3 tomllib parsed both edited TOML files and found npm:@tobilu/qmd='latest'.
- tomllint mise/config.toml mise/config-test.toml passed.
- Project TOML lint command `for f in **/*.toml; do [ -f "$f" ] && tomllint "$f"; done` passed.

Fix round reopened after reviewer note and user clarification: standalone Pi/Herdr agent-stack installer must install qmd through mise, not raw npm.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Removed the deprecated mise plugin_autoupdate_last_check_duration setting and obsolete comment block from both workstation mise configs, then added npm:@tobilu/qmd to the managed npm tools so qmd is installed by the dotfiles toolchain. Verified no deprecated TOML key remains, both qmd manifest entries exist, edited TOML parses with python3 tomllib, and tomllint passes.
<!-- SECTION:FINAL_SUMMARY:END -->
