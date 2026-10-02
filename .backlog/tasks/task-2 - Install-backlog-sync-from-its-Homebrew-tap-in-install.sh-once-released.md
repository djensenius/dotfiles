---
id: TASK-2
title: Install backlog-sync from its Homebrew tap in install.sh once released
status: Done
assignee:
  - '@david'
created_date: '2026-10-01 16:04'
updated_date: '2026-10-02 03:18'
labels: []
dependencies: []
references:
  - 'https://github.com/djensenius/backlog-sync'
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
backlog-sync is released from djensenius/backlog-sync. The opt-in agent-stack installer (pi/agent-stack/install.sh, run by ./install-agent-stack) already installs backlog-md via install_backlog_cli, but repositories that mirror their backlog also need the backlog-sync binary, so they shouldn't have to build it by hand. Depends on djensenius/backlog-sync's Homebrew formula task (djensenius/tap/backlog-sync must exist first).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 pi/agent-stack/install.sh installs backlog-sync with `brew install djensenius/tap/backlog-sync` only on macOS with Homebrew, next to install_backlog_cli, and skips it when already on PATH
- [x] #2 A failed install warns and continues (like install_backlog_cli)
- [x] #3 The final setup hint in pi/agent-stack/install.sh mentions backlog-sync and links to djensenius/backlog-sync for non-Homebrew installs
- [x] #4 pi/agent-stack/tests/install-runtime.sh covers install, already-installed (zero brew calls) and brew-failure cases
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update pi/agent-stack/install.sh so macOS Homebrew installs both backlog-md and djensenius/tap/backlog-sync when missing.
2. Update runtime installer tests and brew mocks to cover backlog-sync install, existing binary skip, and failure warning behavior.
3. Run the affected pi/agent-stack installer runtime test and commit the task/update evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented agent-stack Homebrew install support for backlog-sync. `pi/agent-stack/install.sh` now installs `djensenius/tap/backlog-sync` on macOS with Homebrew when `backlog-sync` is missing, skips when it is already on PATH, warns and continues on install failure, and updates the final setup hint with the backlog-sync repository link for non-Homebrew installs. Updated `pi/agent-stack/tests/install-runtime.sh` brew mocks and assertions for install, already-installed, and failure cases. Validation: `bash pi/agent-stack/tests/install-runtime.sh` passed with output `installer mise runtime tests passed`.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Updated the opt-in Pi/Herdr agent-stack installer to install the released `djensenius/tap/backlog-sync` Homebrew formula alongside `backlog-md`, while preserving skip-on-existing and warn-and-continue failure behavior. Updated runtime installer tests to cover install, already-installed, and brew-failure cases for backlog-sync, plus the final non-Homebrew setup hint linking to `djensenius/backlog-sync`. Verified with `bash pi/agent-stack/tests/install-runtime.sh`.
<!-- SECTION:FINAL_SUMMARY:END -->
