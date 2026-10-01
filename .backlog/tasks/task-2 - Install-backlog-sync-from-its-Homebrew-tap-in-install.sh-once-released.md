---
id: TASK-2
title: Install backlog-sync from its Homebrew tap in install.sh once released
status: To Do
assignee:
  - '@djensenius'
created_date: '2026-10-01 16:04'
updated_date: '2026-10-01 16:04'
labels: []
dependencies: []
references:
  - 'https://github.com/djensenius/backlog-sync'
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
install.sh already installs backlog-md for Codespaces/bootstrap environments. backlog-sync is released from djensenius/backlog-sync. This task depends on the djensenius/backlog-sync Homebrew packaging task being complete before dotfiles installs it from the tap.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 When Homebrew is available and backlog-sync has been released to its tap, install.sh installs it with `brew install djensenius/tap/backlog-sync`.
- [ ] #2 If the backlog-sync Homebrew install fails, install.sh warns without failing the rest of the bootstrap.
- [ ] #3 The install/help hint that mentions backlog-md or Backlog.md tooling is updated to include backlog-sync where appropriate.
- [ ] #4 A test or install-script check is added or updated to cover the backlog-sync install path.
<!-- AC:END -->
