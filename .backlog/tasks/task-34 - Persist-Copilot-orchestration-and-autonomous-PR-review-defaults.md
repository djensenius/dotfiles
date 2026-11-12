---
id: TASK-34
title: Persist Copilot orchestration and autonomous PR review defaults
status: Done
assignee:
  - '@copilot-worker'
created_date: '2026-11-12T17:19:00Z'
updated_date: '2026-11-12T17:48:00Z'
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
- [x] #1 Copilot automatically loads shared personal instructions for planning, research, appropriate fleet/worktree delegation, bounded parallelism, and autonomous delivery while respecting explicit user and repository scope.
- [x] #2 Coordinator owns local review and Copilot review after every push, addresses or explains and resolves feedback, and merges only with completed current-head Copilot review, satisfied feedback, and exact-head green checks using a head-guarded normal merge.
- [x] #3 A reusable opt-in coordinator tick reconciles known agent IDs once, dependency-ready work, owned disk/build cleanup and limits, and stops when work is done or genuinely blocked without assuming a built-in SQL agents table.
- [x] #4 Installation respects COPILOT_HOME, preserves unrelated personal instructions, remains idempotent, and retains Pi behavior; focused runtime tests and actual Copilot instruction discovery verify deployment.
- [x] #5 Shared and repository coordinator instructions plus README consistently explain the Copilot defaults and how to opt into scheduling without repeating the full prompt.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add role-aware personal Copilot defaults and an opt-in reusable tick using documented CLI interfaces. 2. Install additive symlinks with preservation/idempotence, align shared/root rules and README while retaining Pi. 3. Verify full runtime fixtures, syntax/shellcheck, real isolated Copilot discovery, and complete local source review. 4. Finalize verified instruction/installer criteria on the task branch, obtain exact-head Copilot PR review and green CI, merge normally, then activate and verify canonical user-home symlinks before reporting delivery.

Fix round for PR#507 HIGH: guard link_file with same-file identity before any removal or backup, including paths reached through symlinked parent directories. Add isolated fixture repository assets and both personal parent-directory symlinks; install twice and verify sources remain regular readable byte-identical files with no self-links/backups. Run syntax, shellcheck and full installer runtime suite; restore AC4 and Done only after finalization evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented additive symlinked personal defaults and opt-in tick, installer exposure and isolated behavior fixtures, consistent Copilot/Pi root/template/README. Final checks: bash syntax checks passed; shellcheck passed; git diff --check passed; copilot-defaults-preservation passed; copilot-default-home passed; installer mise runtime tests passed. Initial shellcheck SC2016 was fixed by correctly escaping the child-shell argument; initial runtime assertion captured stdout only although backup warnings use stderr, fixed stream capture without weakening the assertion, then full suite passed. Actual isolated copilot instruction list --json recognized label dotfiles-coordinator.instructions.md, location user, sourcePath in this worktree, defaultDisabled false. Managed Backlog block unchanged; root/template common rules match; README link targets exist; owned discovery/runtime scratch removed. No user-home activation, schedule, push, PR, merge or other-repository work performed. AC5 documentation consistency verified; AC1/4 await canonical post-merge activation and discovery; AC2/3 policy assets are ready but live PR/scheduled behavior was deliberately not exercised and remains coordinator evidence. Keep In Progress. Backlog CLI auto-commits task mutations without implementation trailers; do not rewrite those commits.

Local reviewer e57bfc45-c7d9-4f21-a51e-9a083bb9ea35 APPROVE on exact source commit 6403c3e5a82d00e7376cbf0a3e8d70542f33c2fe, consuming all 730 source-diff lines and seven source files; independently confirmed syntax, shellcheck, diff whitespace, preservation/default-home/full runtime fixtures. AC1 and AC4 are verified by real Copilot CLI discovery in the isolated installed COPILOT_HOME plus preservation/idempotence fixtures, not by code presence. AC2/3 are instruction-policy deliverables verified through complete local review against the requested merge/tick safety behavior; no unrelated PR or schedule is required or launched as a test. Canonical user-home activation and discovery remain the coordinator post-merge delivery gate and are not claimed performed yet.

Copilot thread PRRT_kwDOEvktac62wCKQ (comment 4554133416) identifies source/destination identity, not an ordinary conflicting file: a personal instructions/prompts parent symlink makes the destination resolve to the source inode, and the existing identical-content branch removes the source then links it to itself. Reopened task and AC4 while fixing this destructive case; no canonical/home activation.

PR#507 HIGH fix verified: link_file now checks same-file identity (-ef) before any removal/backup, including a regular destination reached through an absolute or relative parent symlink. Focused fixture uses disposable repository sources and both linked personal parent directories, installs twice, and proves readable regular byte-identical source files, unchanged parent links and no source/personal backups. The original pushed installer was rejected by this regression as expected: installer runtime test failed: copilot-defaults-linked-parents installation 1 replaced the source with a self-link. Fixed focused test: copilot-defaults-linked-parents passed; fixed installer passed focused regression. Final full suite: copilot-defaults-preservation passed; copilot-default-home passed; copilot-defaults-linked-parents passed; installer mise runtime tests passed. bash syntax checks passed; shellcheck passed; git diff --check passed. Fixed installer actual isolated Copilot discovery passed with user source dotfiles-coordinator.instructions.md and defaultDisabled false. All owned regression/discovery/runtime fixtures cleaned. AC4 restored based on isolated behavior/discovery evidence; canonical user-home deployment remains coordinator-only after merge. No push, PR/comment action, merge, schedule or home activation.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added automatic, role-aware Copilot personal instructions and an opt-in coordinator tick, with additive symlink deployment, matching shared/root coordinator rules, and usage documentation. Real isolated Copilot instruction discovery, preservation/custom-home/idempotence/Pi runtime fixtures, syntax, shellcheck and complete local review passed. The coordinator still must complete PR review/CI/merge and activate canonical user-home symlinks before reporting delivery; no schedule is installed or started.

Fix round: prevented source deletion/self-links when personal parent directories already symlink to repository instruction/prompt directories. Focused regression fails against the original pushed installer and passes the fixed helper; full existing runtime/Pi preservation checks, syntax, shellcheck and actual isolated discovery passed. Ready for coordinator local review, push/re-request Copilot review, exact-head CI and canonical post-merge activation.
<!-- SECTION:FINAL_SUMMARY:END -->
