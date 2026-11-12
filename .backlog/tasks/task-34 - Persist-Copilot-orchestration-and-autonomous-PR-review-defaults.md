---
id: TASK-34
title: Persist Copilot orchestration and autonomous PR review defaults
status: In Progress
assignee:
  - '@copilot-worker'
created_date: '2026-11-12T17:19:00Z'
updated_date: '2026-11-12T17:25:00Z'
labels: []
dependencies: []
ordinal: 30000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The owner has switched from Pi to Copilot CLI and currently repeats agent orchestration, PR feedback resolution, merge, and coordinator scheduling instructions each session. Persist those defaults in shared Copilot assets and installer support without removing Pi support, launching a schedule, or changing other repositories.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Copilot automatically loads shared personal instructions for planning, research, appropriate fleet/worktree delegation, bounded parallelism, and autonomous delivery while respecting explicit user and repository scope.
- [ ] #2 Coordinator owns local review and Copilot review after every push, addresses or explains and resolves feedback, and merges only with completed current-head Copilot review, satisfied feedback, and exact-head green checks using a head-guarded normal merge.
- [ ] #3 A reusable opt-in coordinator tick reconciles known agent IDs once, dependency-ready work, owned disk/build cleanup and limits, and stops when work is done or genuinely blocked without assuming a built-in SQL agents table.
- [ ] #4 Installation respects COPILOT_HOME, preserves unrelated personal instructions, remains idempotent, and retains Pi behavior; focused runtime tests and actual Copilot instruction discovery verify deployment.
- [ ] #5 Shared and repository coordinator instructions plus README consistently explain the Copilot defaults and how to opt into scheduling without repeating the full prompt.
<!-- AC:END -->
