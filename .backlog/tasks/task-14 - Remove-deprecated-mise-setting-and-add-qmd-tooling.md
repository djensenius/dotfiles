---
id: TASK-14
title: Remove deprecated mise setting and add qmd tooling
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-10 03:37'
updated_date: '2026-10-10 03:37'
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
- [ ] #1 No repository mise config contains `plugin_autoupdate_last_check_duration`.
- [ ] #2 The managed workstation tool manifest includes qmd so `memory_search` prerequisites are installed with the dotfiles toolchain.
- [ ] #3 Validation confirms the deprecated setting is gone and the edited TOML remains parseable.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the mise configs to locate the deprecated setting and workstation tool manifest entries.\n2. Remove plugin_autoupdate_last_check_duration and its explanatory comment block from both mise configs.\n3. Add qmd via npm:@tobilu/qmd to the managed workstation tools, keeping config-test aligned where it mirrors the workstation manifest.\n4. Validate the deprecated key is absent and both edited TOML files parse successfully; run targeted relevant checks.\n5. Record evidence, finalize the Backlog task, and commit the Backlog and config changes.
<!-- SECTION:PLAN:END -->
