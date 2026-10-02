---
id: TASK-1
title: Mirror this repo's backlog to a GitHub Project with backlog-sync
status: Done
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
- [x] #1 A GitHub Project exists for djensenius/dotfiles with To Do, In Progress, and Done columns/statuses mapped from Backlog.md.
- [x] #2 `.backlog-sync.json` is added with `defaultRepo` set to `djensenius/dotfiles` and inbox mode set to manual.
- [x] #3 A launchd agent is installed with its own label and log files for the backlog-sync mirror.
- [x] #4 A real backlog-sync run is recorded with its result, followed by a no-op second run recorded with its result.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Create or reuse a user-owned GitHub Project titled dotfiles, verify the Status field has To Do, In Progress, and Done options, and record the project number/URL. 2. Add a repo .backlog-sync.json based on upstream minimal-single-repo config with defaultRepo djensenius/dotfiles and inbox.mode manual. 3. Add an idempotent launchd installer plus repo-owned plist template for com.djensenius.dotfiles.backlog-sync using /Users/david/bin/backlog-sync, repo-root -root/-config, -no-inbox, unique /tmp logs, then install/load it from this worktree. 4. Run backlog-sync dry-run, then two real -root . -config .backlog-sync.json -no-inbox -verbose runs, recording the first real sync and second no-op evidence in task notes. 5. Validate plist, diff, and task criteria before finalizing TASK-1.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
GitHub Project: created user-owned project 'dotfiles' number 10 at https://github.com/users/djensenius/projects/10 (id PVT_kwHOAAvwsM4BlZoW). Verified Status field PVTSSF_lAHOAAvwsM4BlZoWzhkGqak options are To Do, In Progress, and Done with gh project field-list 10 --owner djensenius --format json. Synced items after the run: issues #365-#374 across TASK-1 through TASK-10 with statuses In Progress/To Do/Done as shown by gh project item-list 10.

Config/schema: confirmed /Users/david/bin/backlog-sync version=dev commit=358dbcd7f5b2 date=unknown supports -config, -dry-run, -no-inbox, -repo, and -root. Confirmed upstream README/examples define projectOwner/projectOwnerType/projectNumber/defaultRepo/mainBranch/statusMap and inbox.mode manual. Added .backlog-sync.json with projectNumber 10, defaultRepo djensenius/dotfiles, inbox.enabled true, inbox.label inbox, and inbox.mode manual.

Dry run: /Users/david/bin/backlog-sync -dry-run -root . -config .backlog-sync.json -no-inbox -verbose scanned /Users/david/Developer/dotfiles/.backlog, this worktree .backlog, and task-10 worktree .backlog, then reported: sync complete: 10 created, 0 updated, 10 status changes, 0 imported, 0 inbox issues need triage, 0 failed operations.

Launchd: scripts/install-dotfiles-backlog-sync-launchd.sh --root /Users/david/Developer/dotfiles-task-1-backlog-sync-mirror wrote /Users/david/Library/LaunchAgents/com.djensenius.dotfiles.backlog-sync.plist. plutil -lint passed. The installed agent uses label com.djensenius.dotfiles.backlog-sync, /Users/david/bin/backlog-sync, -root /Users/david/Developer/dotfiles-task-1-backlog-sync-mirror, -config /Users/david/Developer/dotfiles-task-1-backlog-sync-mirror/.backlog-sync.json, -no-inbox, -verbose, stdout /tmp/dotfiles-backlog-sync.out.log, and stderr /tmp/dotfiles-backlog-sync.err.log. Loaded with --load; launchctl list showed com.djensenius.dotfiles.backlog-sync exit 0 after RunAtLoad, and the stdout log ended with sync complete: 0 created, 0 updated, 0 status changes, 0 imported, 0 inbox issues need triage, 0 failed operations.

Real sync: /Users/david/bin/backlog-sync -root . -config .backlog-sync.json -no-inbox -verbose created issues djensenius/dotfiles#365-#374, added them to project 10, set statuses, and ended: sync complete: 10 created, 8 updated, 10 status changes, 0 imported, 0 inbox issues need triage, 0 failed operations. Immediate second run of the same command ended: sync complete: 0 created, 0 updated, 0 status changes, 0 imported, 0 inbox issues need triage, 0 failed operations.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented the dotfiles backlog-sync mirror by creating GitHub Project #10, adding .backlog-sync.json with defaultRepo djensenius/dotfiles and manual inbox mode, adding and installing/loading the launchd mirror agent, and running a real sync plus immediate no-op second run. Verified project status options/items with gh project commands, config with upstream README/examples and backlog-sync -dry-run, launchd with plutil/launchctl/logs, and sync output showing 10 created then 0 changes.
<!-- SECTION:FINAL_SUMMARY:END -->
