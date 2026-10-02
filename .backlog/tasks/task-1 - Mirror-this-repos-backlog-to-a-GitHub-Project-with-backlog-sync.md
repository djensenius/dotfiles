---
id: TASK-1
title: Mirror this repo's backlog to a GitHub Project with backlog-sync
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 16:04'
updated_date: '2026-10-02 01:44'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Create or reuse a user-owned GitHub Project titled dotfiles, verify the Status field has To Do, In Progress, and Done options, and record the project number/URL. 2. Add a repo .backlog-sync.json based on upstream minimal-single-repo config with defaultRepo djensenius/dotfiles and inbox.mode manual. 3. Add an idempotent launchd installer plus repo-owned plist template for com.djensenius.dotfiles.backlog-sync using /Users/david/bin/backlog-sync, repo-root -root/-config, -no-inbox, unique /tmp logs, then install/load it from this worktree. 4. Run backlog-sync dry-run, then two real -root . -config .backlog-sync.json -no-inbox -verbose runs, recording the first real sync and second no-op evidence in task notes. 5. Validate plist, diff, and task criteria before finalizing TASK-1.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
GitHub Project: created user-owned project 'dotfiles' number 10 at https://github.com/users/djensenius/projects/10 (id PVT_kwHOAAvwsM4BlZoW). Verified Status field PVTSSF_lAHOAAvwsM4BlZoWzhkGqak options are To Do, In Progress, and Done with gh project field-list 10 --owner djensenius --format json. Synced items after the run: issues #365-#374 across TASK-1 through TASK-10 with statuses In Progress/To Do/Done as shown by gh project item-list 10.
<!-- SECTION:NOTES:END -->
