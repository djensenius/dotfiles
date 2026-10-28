---
id: TASK-26
title: Clarify stale Herdr server and client update guidance
status: In Progress
assignee:
  - '@copilot-worker'
created_date: 2026-10-15 13:54
updated_date: '2026-10-28T18:37:00Z'
labels: []
dependencies: []
modified_files:
  - README.md
  - herdr/scripts/herdr-image-doctor.sh
type: docs
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-22 local status evidence showed `herdr` client 0.9.4 from mise with a running server at 0.9.1 and `server_binary_stale=true`. README.md already mentions `herdr update --handoff`, and `herdr/scripts/herdr-image-doctor.sh` already prints stale-server guidance. Narrow this follow-up to making that existing guidance consistent and discoverable without duplicating it in a third place: mise manages the installed binary, while Herdr handoff or restart fixes stale runtime state.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Review the existing guidance in `README.md` and `herdr/scripts/herdr-image-doctor.sh`, then update only the minimum necessary locations to avoid duplicating the same advice in a third place.
- [ ] #2 Docs or status-helper output clearly explain when to use `herdr update --handoff` or restart Herdr versus when to run `mise install` for the binary.
- [ ] #3 The guidance covers the stale server/client mismatch shown by `herdr status --json`.
- [ ] #4 Relevant markdown or shell validation is run, or the task records why manual documentation review is sufficient.
<!-- AC:END -->
