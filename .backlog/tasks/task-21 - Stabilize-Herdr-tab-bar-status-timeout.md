---
id: TASK-21
title: Stabilize Herdr tab bar status timeout
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-15 13:46'
updated_date: '2026-10-15 13:46'
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
- [ ] #1 Herdr tab bar status command timeout is increased enough to avoid observed 2 second flicker
- [ ] #2 The status command interval remains documented/unchanged unless there is evidence the expensive package poller interval is affected
- [ ] #3 The resulting change is committed on a task branch and ready for PR review
<!-- AC:END -->
