---
id: TASK-21
title: Stabilize Herdr tab bar status timeout
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-15 13:46'
updated_date: '2026-10-15 13:47'
labels: []
dependencies: []
ordinal: 19000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Herdr's tab bar status command is configured with a 2 second timeout, but the status helper can occasionally take longer while rendering battery/package state. When that happens Herdr logs timeout warnings and the right-side status area can disappear and reappear.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Herdr tab bar status command timeout is increased enough to avoid observed 2 second flicker
- [x] #2 The status command interval remains documented/unchanged unless there is evidence the expensive package poller interval is affected
- [x] #3 The resulting change is committed on a task branch and ready for PR review
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update herdr/config.toml so the tab_bar_right status command keeps interval_seconds at 5 and raises timeout_seconds from 2 to 5.
2. Verify the resulting TOML line and run a lightweight config/TOML parse check before finalizing the task.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Changed herdr/config.toml tab_bar_right command timeout_seconds from 2 to 5 while leaving interval_seconds at 5. Validation evidence:
- sed -n "53p" herdr/config.toml -> { type = "command", command = "~/.config/herdr/scripts/herdr-status-report.sh --tab-bar", interval_seconds = 5, timeout_seconds = 5 },
- python3 tomllib parse asserted interval_seconds=5 and timeout_seconds=5; output: parsed-timeouts: interval_seconds=5 timeout_seconds=5
- herdr config check output: config: ok
- tomllint herdr/config.toml skipped because tomllint was not found on PATH.
<!-- SECTION:NOTES:END -->
