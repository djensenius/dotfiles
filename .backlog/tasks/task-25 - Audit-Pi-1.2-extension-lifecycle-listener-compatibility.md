---
id: TASK-25
title: Audit Pi 1.2 extension lifecycle listener compatibility
status: Done
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
- [x] #1 Pi 1.2.0 lifecycle event names are confirmed from release notes, API docs, or runtime inspection.
- [x] #2 Repo extensions are updated if `agent_start` is no longer correct, or the task records evidence that the current listener remains compatible.
- [x] #3 `node ai-tools/tests/subagent-status.test.ts` passes after any extension changes, or the task records why no code change was required.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Audit the existing listener and coverage against installed Pi core release notes/docs and the official v1.2.0 API/event dispatch.
2. Retain source and tests unchanged if agent_start remains supported; record authoritative versioned references and compatibility rationale.
3. Run the existing subagent-status test, record its exact output, verify acceptance criteria, and finalize TASK-25 only.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Compatibility audit completed without source or test changes.

Authoritative Pi core evidence (not inferred from pi-subagents):
- Installed binary resolved by both command -v pi and mise which pi: /Users/david/.local/share/mise/installs/pi/latest/pi/pi. pi --version output: 1.4.0. Adjacent package.json:2-3 identifies @earendil-works/pi-coding-agent 1.4.0.
- Exact Pi 1.2.0 API: https://github.com/earendil-works/pi/blob/v1.2.0/packages/coding-agent/src/core/extensions/types.ts#L959-L962 defines AgentStartEvent with type: "agent_start"; lines 1642-1643 expose on(event: "agent_start", handler: ExtensionHandler<AgentStartEvent>) and agent_end. Retrieved directly from the official v1.2.0 raw source.
- Exact Pi 1.2.0 runtime dispatch: https://github.com/earendil-works/pi/blob/v1.2.0/packages/coding-agent/src/core/agent-session.ts#L1288-L1292 forwards agent_start to this._extensionRunner.emit({ type: "agent_start" }) and agent_end to its corresponding event. This confirms runtime delivery as well as API naming.
- /Users/david/.local/share/mise/installs/pi/latest/pi/CHANGELOG.md:105-119 contains the 1.2.0 release dated 2026-10-12. Its lifecycle breaking changes concern before_agent_start (custom-message runs, messageType union) and startup busy/queue semantics, not an agent_start rename.
- /Users/david/.local/share/mise/installs/pi/latest/pi/docs/extensions.md:115-121 still lists before_agent_start, agent_start/agent_end, turn_start/turn_end and settlement events; lines 150-162 distinguish low-level run observation (agent_start/agent_end) from input, settlement and session lifecycle hooks.

Repo comparison / closure rationale:
- ai-tools/extensions/subagent-status.ts:204-208 registers agent_start, takes no event payload, and only clears the attention set and re-renders. It neither consumes the changed before_agent_start payload nor changes active/busy fleet counts. The listener remains supported; no rename or adaptation is needed.
- ai-tools/tests/subagent-status.test.ts:148-158 already exercises attention being cleared at agent_start while the five-subagent count remains visible, then accepts a fresh attention request. No redundant tests added. These unit tests use a fake event bus; actual Pi 1.2.0 delivery is established by the authoritative core dispatch above, not claimed as a live model-run integration test.

Checks (all run in /Users/david/Developer/dotfiles-task-25):
- node ai-tools/tests/subagent-status.test.ts: exit 0; exact output: subagent-status tests passed
- The existing test runner emits only that aggregate success line, not individual per-test lines; no additional per-test output was fabricated.
- git diff --check: exit 0; no output.
- pi --version: exit 0; exact output: 1.4.0

Only TASK-25 task state/evidence changed. No source, tests, installation, configuration, main checkout, push, PR or merge changes; no follow-up required for the audited lifecycle-name compatibility.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Confirmed agent_start remains compatible using official Pi v1.2.0 extension API declarations and runtime dispatch, plus installed Pi 1.4.0 core docs and 1.2.0 release notes. The changed before_agent_start payload is unused by this extension. Retained existing source/tests unchanged; node ai-tools/tests/subagent-status.test.ts printed "subagent-status tests passed" (exit 0), and git diff --check passed. All acceptance criteria verified; no lifecycle compatibility follow-up needed.
<!-- SECTION:FINAL_SUMMARY:END -->
