---
id: TASK-2
title: Install backlog-sync from its Homebrew tap in install.sh once released
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 16:04'
updated_date: '2026-10-02 03:13'
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
