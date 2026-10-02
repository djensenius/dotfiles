---
id: TASK-1
title: Mirror this repo's backlog to a GitHub Project with backlog-sync
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 16:04'
updated_date: '2026-10-02 01:39'
labels: []
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The owner tracks every repository's work on GitHub Projects. This dotfiles board needs a backlog-sync mirror after Backlog.md adoption so the GitHub Project remains the live board without adding mirror config before the adoption PR lands.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A GitHub Project exists for djensenius/dotfiles with To Do, In Progress, and Done columns/statuses mapped from Backlog.md.
- [ ] #2 `.backlog-sync.json` is added with `defaultRepo` set to `djensenius/dotfiles` and inbox mode set to manual.
- [ ] #3 A launchd agent is installed with its own label and log files for the backlog-sync mirror.
- [ ] #4 A real backlog-sync run is recorded with its result, followed by a no-op second run recorded with its result.
<!-- AC:END -->
