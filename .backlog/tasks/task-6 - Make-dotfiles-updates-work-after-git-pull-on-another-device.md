---
id: TASK-6
title: Make dotfiles updates work after git pull on another device
status: To Do
assignee: []
created_date: '2026-10-01 17:26'
labels: []
dependencies:
  - TASK-4
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Dotfiles changes should become usable on another machine after a normal git pull, like the prior symlink-based setup. Some generated, installed, or machine-local configuration may currently require extra manual install steps, which makes cross-device updates brittle.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Document the expected "git pull on another device" workflow and any one-time prerequisites
- [ ] #2 Repo-managed dotfiles that should update automatically are linked or installed in a repeatable way without overwriting machine-local secrets
- [ ] #3 Pi/Herdr/agent-stack config changes from repo updates are applied by the documented workflow or clearly called out when a package reinstall is required
- [ ] #4 Validation covers at least one dry-run or safe check proving the workflow detects/applies the relevant symlinks or install targets
<!-- AC:END -->
