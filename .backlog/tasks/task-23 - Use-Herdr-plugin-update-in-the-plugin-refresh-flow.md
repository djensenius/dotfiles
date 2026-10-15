---
id: TASK-23
title: Use Herdr plugin update in the plugin refresh flow
status: To Do
assignee: []
created_date: '2026-10-15 13:54'
labels: []
dependencies: []
modified_files:
  - herdr/scripts/herdr-cli-update.sh
  - README.md
type: task
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-22 found that the repo Herdr plugin refresher still reinstalls each plugin with `herdr plugin install <plugin> --yes`, while current Herdr exposes `herdr plugin update`. Refreshing via the native update command should reduce needless reinstall behavior without dropping compatibility for older Herdr binaries.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 When `herdr plugin update` is available, the Herdr plugin refresh flow uses it instead of reinstalling every plugin.
- [ ] #2 Older Herdr versions without `herdr plugin update` still have a working fallback or a clear actionable message.
- [ ] #3 Any README/help text touched by the flow no longer describes native plugin updates as reinstall-only.
- [ ] #4 Validation covers the updated shell path, with the exact command output recorded in the task.
<!-- AC:END -->
