---
id: TASK-3
title: Adopt Backlog.md and the PR workflow in dotfiles
status: To Do
assignee: []
created_date: '2026-10-01 16:05'
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
- [ ] #1 `.backlog/config.yml` initializes the dotfiles Backlog.md board with auto-commit and active-branch checks enabled.
- [ ] #2 Root `AGENTS.md` is based on `pi/agent-stack/templates/AGENTS.md`, includes dotfiles-specific project notes, and has the Backlog.md managed instructions refreshed.
- [ ] #3 Copilot review skip instructions cover `.backlog/**`, and no `.backlog-sync.json` is added during adoption.
- [ ] #4 Backlog follow-up tasks exist for the GitHub Project/backlog-sync mirror and for installing backlog-sync from the Homebrew tap once released.
- [ ] #5 Changed YAML and Markdown files are validated with the repository's relevant lint/link checks.
<!-- AC:END -->
