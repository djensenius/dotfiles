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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review the existing README and image-doctor guidance against installed Herdr help/status and mise configuration. 2. Clarify only the existing README stale-runtime bullet: distinguish mise-managed binary installation from server handoff/restart and client reattachment, using actual JSON field paths. Preserve TASK-23 plugin guidance and leave the doctor unchanged. 3. Validate the focused Markdown diff, relevant local links, and authoritative help/status evidence; record acceptance evidence and finalize TASK-26.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Reviewed README.md Kitty graphics guidance and herdr/scripts/herdr-image-doctor.sh diagnosis item 4. Installed `herdr update --help` says "Download and install the latest version" and `--handoff` says "Try live handoff after installing". Read-only `herdr status --json` confirms nested client.version=0.9.5, server.version=0.9.4, server.server_binary_stale=true, and client.binary under mise/installs/herdr/latest. mise/config.toml configures herdr = latest. README alone can supply the missing distinction without a third guidance location or shell changes.
<!-- SECTION:NOTES:END -->
