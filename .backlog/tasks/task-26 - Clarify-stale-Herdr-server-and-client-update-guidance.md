---
id: TASK-26
title: Clarify stale Herdr server and client update guidance
status: To Do
assignee: []
created_date: '2026-10-15 13:54'
labels: []
dependencies: []
modified_files:
  - README.md
  - herdr/scripts/herdr-cli-update.sh
type: docs
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-22 local status evidence showed `herdr` client 0.9.4 from mise with a running server at 0.9.1 and `server_binary_stale=true`. The repo already mentions `herdr update --handoff`, but user-facing guidance should make the split clear: mise manages the installed binary, while Herdr handoff or restart fixes stale runtime state.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Docs or status-helper output clearly explain when to use `herdr update --handoff` or restart Herdr versus when to run `mise install` for the binary.
- [ ] #2 The guidance covers the stale server/client mismatch shown by `herdr status --json`.
- [ ] #3 Relevant markdown or shell validation is run, or the task records why manual documentation review is sufficient.
<!-- AC:END -->
