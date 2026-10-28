---
id: TASK-23
title: Use Herdr plugin update in the plugin refresh flow
status: In Progress
assignee:
  - '@copilot-worker'
created_date: 2026-10-15 13:54
updated_date: '2026-10-28T18:28:00Z'
labels: []
dependencies: []
modified_files:
  - herdr/scripts/herdr-cli-update.sh
  - herdr/tests/herdr-cli-update-test.sh
  - README.md
type: task
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-22 found that the repo Herdr plugin refresher currently reinstalls each outdated plugin listed in the cache with `herdr plugin install <plugin> --yes`, while current Herdr exposes `herdr plugin update`. Refreshing outdated cached plugins via the native update command should reduce needless reinstall behavior without dropping compatibility for older Herdr binaries.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Confirm `herdr plugin update` exists and its argument form via `herdr plugin update --help` before changing the flow.
- [ ] #2 When `herdr plugin update` is available, the Herdr plugin refresh flow uses it instead of reinstalling each outdated plugin from the cache.
- [ ] #3 Older Herdr versions without `herdr plugin update` still have a working fallback or a clear actionable message.
- [ ] #4 Preserve the existing owner/repo plugin-name validation and `</dev/null` safety in the refreshed shell path.
- [ ] #5 Any README/help text touched by the flow no longer describes native plugin updates as reinstall-only.
- [ ] #6 Validation runs `bash herdr/tests/herdr-cli-update-test.sh` and records the exact command output in the task.
<!-- AC:END -->
