---
id: TASK-1
title: Mirror this repo's backlog to a GitHub Project with backlog-sync
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 16:04'
updated_date: '2026-10-02 02:40'
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

Coordinator follow-up after initial completion: subagent reviewer/worker attempts failed with provider Connection error (reported as recurring 400s). Direct investigation found the dotfiles LaunchAgent had been loaded from the task worktree; it was booted out to avoid a persistent agent pointing at a disposable checkout. backlog-sync upstream docs confirm cross-worktree scanning is intentional, but the launchd installer should prevent --load from non-main/task worktrees unless explicitly overridden.

Fix checkpoint: updated scripts/install-dotfiles-backlog-sync-launchd.sh so --load refuses to bootstrap com.djensenius.dotfiles.backlog-sync from a non-main checkout unless --allow-non-main-root is explicitly passed. Validation: scripts/install-dotfiles-backlog-sync-launchd.sh --root "$PWD" --load exits 2 with a refusal naming task-1-backlog-sync-mirror vs expected main; plutil -lint launchd/com.djensenius.dotfiles.backlog-sync.plist.template -> OK; git diff --check -> no output. The dotfiles LaunchAgent remains unloaded.

Homebrew follow-up: owner noted backlog-sync should now be installed from Homebrew. Verified `command -v backlog-sync` -> `/opt/homebrew/bin/backlog-sync`, `backlog-sync -version` -> `version=0.1.0 commit=0eca8d7caf8d727f2bbc54c54c14bd9607388f6d date=2026-10-02T02:03:15Z`, and `brew list --versions backlog-sync` -> `backlog-sync 0.1.0`. Updated `scripts/install-dotfiles-backlog-sync-launchd.sh` to default to the first `backlog-sync` on PATH instead of hard-coding `/Users/david/bin/backlog-sync`. Validation after rebase onto origin/main: `scripts/install-dotfiles-backlog-sync-launchd.sh --root "$PWD" --load` exits 2 and refuses to load from branch `task-1-backlog-sync-mirror` instead of main; `plutil -lint launchd/com.djensenius.dotfiles.backlog-sync.plist.template` -> OK; bounded dry-run with `timeout 120 backlog-sync -dry-run -root . -config .backlog-sync.json -no-inbox -verbose` completed with `sync complete: 1 created, 1 updated, 2 status changes, 0 imported, 0 inbox issues need triage, 0 failed operations`; `bash -n scripts/install-dotfiles-backlog-sync-launchd.sh`, `shellcheck scripts/install-dotfiles-backlog-sync-launchd.sh`, `yamllint .`, and `git diff --check` all passed with no output. The dotfiles LaunchAgent remains intentionally unloaded until this branch lands on main, then it should be installed from the canonical checkout with `scripts/install-dotfiles-backlog-sync-launchd.sh --load`.

Copilot review fix: hardened scripts/install-dotfiles-backlog-sync-launchd.sh so value-taking options (`--root`, `--binary`, `--stdout-log`, `--stderr-log`) validate their argument before dereferencing under `set -u`, and so the non-main checkout guard runs before writing any live plist, not only before `--load`. Validation: non-load run from task branch exits 2 before writing; `--root` without a value exits 2 with usage instead of an unbound variable; explicit `--allow-non-main-root` render succeeded for diagnostics, then the temporary non-main plist was removed and launchctl confirmed the dotfiles service is absent; `bash -n scripts/install-dotfiles-backlog-sync-launchd.sh`, `shellcheck scripts/install-dotfiles-backlog-sync-launchd.sh`, `plutil -lint launchd/com.djensenius.dotfiles.backlog-sync.plist.template`, `yamllint .`, and `git diff --check` passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Configured the dotfiles backlog-sync mirror with GitHub Project #10, `.backlog-sync.json` for `djensenius/dotfiles` and manual inbox mode, and a repo-owned launchd installer/template for `com.djensenius.dotfiles.backlog-sync`. The first implementation created/updated the live mirror and recorded a real sync plus no-op run; follow-up fixes made the persistent installer refuse `--load` from disposable task worktrees and switched the default binary to the Homebrew `backlog-sync` on PATH. Verified Homebrew backlog-sync 0.1.0, launchd plist lint, non-main load guard, bounded dry-run, shell syntax, shellcheck, yamllint, and whitespace checks. After merge, reinstall/load from the canonical main checkout so the LaunchAgent points at `/Users/david/Developer/dotfiles`.
<!-- SECTION:FINAL_SUMMARY:END -->
