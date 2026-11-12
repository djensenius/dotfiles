---
id: TASK-34
title: Persist Copilot orchestration and autonomous PR review defaults
status: In Progress
assignee:
  - '@copilot-worker'
created_date: '2026-11-12T17:19:00Z'
updated_date: '2026-11-12T17:32:00Z'
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
- [x] #5 Shared and repository coordinator instructions plus README consistently explain the Copilot defaults and how to opt into scheduling without repeating the full prompt.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add role-aware personal Copilot coordinator defaults and an explicitly opt-in tick asset, using documented CLI commands and exact-head review/merge gates. 2. Link additive instructions and tick through the existing backup/idempotent helper without replacing personal top-level instructions; align root/template/README while retaining Pi and Backlog rules. 3. Extend isolated runtime fixtures for preservation, conflicts, repeat installs, default/overridden COPILOT_HOME and output; run syntax, available shellcheck, full runtime suite once and isolated actual Copilot discovery. 4. Record objective evidence and remaining post-merge canonical deployment, leave In Progress, and commit implementation with requested trailers.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented additive symlinked personal defaults and opt-in tick, installer exposure and isolated behavior fixtures, consistent Copilot/Pi root/template/README. Final checks: bash syntax checks passed; shellcheck passed; git diff --check passed; copilot-defaults-preservation passed; copilot-default-home passed; installer mise runtime tests passed. Initial shellcheck SC2016 was fixed by correctly escaping the child-shell argument; initial runtime assertion captured stdout only although backup warnings use stderr, fixed stream capture without weakening the assertion, then full suite passed. Actual isolated copilot instruction list --json recognized label dotfiles-coordinator.instructions.md, location user, sourcePath in this worktree, defaultDisabled false. Managed Backlog block unchanged; root/template common rules match; README link targets exist; owned discovery/runtime scratch removed. No user-home activation, schedule, push, PR, merge or other-repository work performed. AC5 documentation consistency verified; AC1/4 await canonical post-merge activation and discovery; AC2/3 policy assets are ready but live PR/scheduled behavior was deliberately not exercised and remains coordinator evidence. Keep In Progress. Backlog CLI auto-commits task mutations without implementation trailers; do not rewrite those commits.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added role-aware automatic Copilot personal defaults and explicitly opt-in coordinator tick, linked through existing preservation/idempotence helpers, with matching Copilot/Pi shared rules and README. Isolated runtime tests, syntax, shellcheck and actual Copilot discovery passed; scratch cleaned. Remains In Progress pending canonical symlink activation after merge, real personal discovery and coordinator review/behavior evidence; no schedule or home deployment performed.
<!-- SECTION:FINAL_SUMMARY:END -->
