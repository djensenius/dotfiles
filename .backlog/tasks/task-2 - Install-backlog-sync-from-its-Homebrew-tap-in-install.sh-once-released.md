---
id: TASK-2
title: Install backlog-sync from its Homebrew tap in install.sh once released
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 16:04'
updated_date: '2026-10-02 03:14'
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
- [ ] #1 pi/agent-stack/install.sh installs backlog-sync with `brew install djensenius/tap/backlog-sync` only on macOS with Homebrew, next to install_backlog_cli, and skips it when already on PATH
- [ ] #2 A failed install warns and continues (like install_backlog_cli)
- [ ] #3 The final setup hint in pi/agent-stack/install.sh mentions backlog-sync and links to djensenius/backlog-sync for non-Homebrew installs
- [ ] #4 pi/agent-stack/tests/install-runtime.sh covers install, already-installed (zero brew calls) and brew-failure cases
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add an install_backlog_sync helper next to install_backlog_cli that is macOS/Homebrew-gated, skips when backlog-sync is on PATH, installs djensenius/tap/backlog-sync with the same Homebrew environment flags, and warns without exiting on failure. 2. Call the helper in the agent-stack install flow beside install_backlog_cli and update the final repository setup hint to mention backlog-sync plus the upstream URL for non-Homebrew installs. 3. Extend install-runtime brew mocks/tests to cover backlog-sync install, already-installed skip with zero brew calls, and brew failure while preserving backlog-md coverage. 4. Run the requested shell/runtime/lint validation and record evidence before finalizing TASK-2.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented backlog-sync Homebrew install helper, wired it into pi/agent-stack/install.sh after install_backlog_cli, updated setup hint with https://github.com/djensenius/backlog-sync, and extended install-runtime brew mocks/tests for install, already-installed zero-brew, and failure paths. Validation: bash pi/agent-stack/tests/install-runtime.sh -> installer mise runtime tests passed; shellcheck pi/agent-stack/install.sh pi/agent-stack/tests/install-runtime.sh -> passed with no output; yamllint . -> passed with no output; git diff --check -> passed with no output.
<!-- SECTION:NOTES:END -->
