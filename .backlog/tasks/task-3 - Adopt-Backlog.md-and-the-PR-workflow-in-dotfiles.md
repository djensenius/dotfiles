---
id: TASK-3
title: Adopt Backlog.md and the PR workflow in dotfiles
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 16:05'
updated_date: '2026-10-01 16:07'
labels: []
dependencies: []
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
dotfiles now has the shared Pi agent-stack template available on origin/main. Adopt Backlog.md in this repository so future coordinator/worker/reviewer sessions use a local .backlog board and PR-only task workflow.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `.backlog/config.yml` initializes the dotfiles Backlog.md board with auto-commit and active-branch checks enabled.
- [x] #2 Root `AGENTS.md` is based on `pi/agent-stack/templates/AGENTS.md`, includes dotfiles-specific project notes, and has the Backlog.md managed instructions refreshed.
- [x] #3 Copilot review skip instructions cover `.backlog/**`, and no `.backlog-sync.json` is added during adoption.
- [x] #4 Backlog follow-up tasks exist for the GitHub Project/backlog-sync mirror and for installing backlog-sync from the Homebrew tap once released.
- [x] #5 Changed YAML and Markdown files are validated with the repository's relevant lint/link checks.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Initialize `.backlog/config.yml` with the requested Backlog.md defaults and branch safety settings.
2. Add root `AGENTS.md` from `pi/agent-stack/templates/AGENTS.md`, fill in dotfiles-specific notes, and refresh the managed Backlog.md instructions.
3. Confirm Copilot skip coverage, create the requested follow-up tasks, validate YAML/Markdown changes, then check criteria and close the task.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Backlog.md adoption on `adopt-backlog-board`: initialized `.backlog/config.yml` for project `dotfiles` with `autoCommit=true` and `checkActiveBranches=true`; added root `AGENTS.md` from `pi/agent-stack/templates/AGENTS.md` with dotfiles setup/lint/test notes and refreshed Backlog.md markers; confirmed `.github/instructions/backlog.instructions.md` applies to `.backlog/**`; created TASK-1 and TASK-2 follow-ups; kept `.backlog-sync.json` absent.

Validation evidence: `yamllint .` passed with no output after adding the YAML document start; README/AGENTS local Markdown link checker passed; AGENTS content checker passed; `git diff --check origin/main..HEAD` passed; `backlog doctor` passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Adopted Backlog.md for `djensenius/dotfiles` on `adopt-backlog-board`: initialized the board config, added root `AGENTS.md` from `pi/agent-stack/templates/AGENTS.md` with dotfiles project notes and managed Backlog.md instructions, confirmed Copilot skip coverage for `.backlog/**`, and created TASK-1/TASK-2 follow-ups instead of adding `.backlog-sync.json`. Verified with `yamllint .`, README/AGENTS local link checking, AGENTS content checking, `git diff --check origin/main..HEAD`, and `backlog doctor`.
<!-- SECTION:FINAL_SUMMARY:END -->
