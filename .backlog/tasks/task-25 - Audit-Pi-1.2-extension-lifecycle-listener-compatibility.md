---
id: TASK-25
title: Audit Pi 1.2 extension lifecycle listener compatibility
status: In Progress
assignee:
  - '@copilot-worker'
created_date: 2026-10-15 13:54
updated_date: '2026-10-28T18:36:00Z'
labels: []
dependencies: []
modified_files:
  - ai-tools/extensions/subagent-status.ts
  - ai-tools/tests/subagent-status.test.ts
type: task
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-22 identified Pi 1.2.0 extension-event changes as a compatibility risk. The repo extension currently listens for `agent_start`, so it needs a targeted audit against Pi 1.2.0 lifecycle event names before changing or relying on that listener.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Pi 1.2.0 lifecycle event names are confirmed from release notes, API docs, or runtime inspection.
- [ ] #2 Repo extensions are updated if `agent_start` is no longer correct, or the task records evidence that the current listener remains compatible.
- [ ] #3 `node ai-tools/tests/subagent-status.test.ts` passes after any extension changes, or the task records why no code change was required.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Audit the existing listener and coverage against installed Pi core release notes/docs and the official v1.2.0 API/event dispatch.
2. Retain source and tests unchanged if agent_start remains supported; record authoritative versioned references and compatibility rationale.
3. Run the existing subagent-status test, record its exact output, verify acceptance criteria, and finalize TASK-25 only.
<!-- SECTION:PLAN:END -->
