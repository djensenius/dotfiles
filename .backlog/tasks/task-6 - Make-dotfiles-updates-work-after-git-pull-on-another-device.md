---
id: TASK-6
title: Make dotfiles updates work after git pull on another device
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 17:26'
updated_date: '2026-10-01 18:29'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Document the post-pull refresh workflow in README.md for macOS, Raspberry Pi, Pi/Herdr agent-stack, and Codespaces boundaries. 2. Add or clarify safe check/dry-run commands that reuse existing installers rather than overwriting local secrets. 3. Validate the documented workflow with existing safe installer checks/tests, especially mac install check/dry-run behavior and agent-stack runtime coverage.
<!-- SECTION:PLAN:END -->
