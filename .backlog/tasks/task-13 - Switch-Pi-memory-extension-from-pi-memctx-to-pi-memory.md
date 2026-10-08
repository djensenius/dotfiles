---
id: TASK-13
title: Switch Pi memory extension from pi-memctx to pi-memory
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-08 13:47'
updated_date: '2026-10-08 13:49'
labels: []
dependencies: []
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The installed pi-memctx extension keeps triggering Pi extension loader warnings because its published package declares @sinclair/typebox under dependencies instead of peerDependencies. The owner asked to switch the repo-managed agent stack to pi-memory, which currently has much higher npm usage and avoids the recurring local pi-memctx manifest workaround.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Repo-managed Pi package configuration installs npm:pi-memory instead of npm:pi-memctx
- [ ] #2 README or relevant agent-stack documentation names pi-memory instead of pi-memctx where the default extension set is documented
- [ ] #3 Agent-stack tests or fixtures that assert the package list are updated consistently
- [ ] #4 The relevant validation checks pass and their output is recorded in the task notes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Replace npm:pi-memctx with npm:pi-memory in the repo-managed Pi package list.
2. Update the README default shared Pi package documentation to name npm:pi-memory.
3. Update install-runtime.sh managed package expectations and validate with the runtime test plus grep consistency checks.
<!-- SECTION:PLAN:END -->
