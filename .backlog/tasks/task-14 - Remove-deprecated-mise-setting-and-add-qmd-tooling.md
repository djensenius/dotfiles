---
id: TASK-14
title: Remove deprecated mise setting and add qmd tooling
status: To Do
assignee: []
created_date: '2026-10-10 03:37'
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
