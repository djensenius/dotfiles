---
id: TASK-26
title: Clarify stale Herdr server and client update guidance
status: Done
assignee:
  - '@copilot-worker'
created_date: 2026-10-15 13:54
updated_date: '2026-10-28T18:38:00Z'
labels: []
dependencies: []
modified_files:
  - README.md
type: docs
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-22 local status evidence showed `herdr` client 0.9.4 from mise with a running server at 0.9.1 and `server_binary_stale=true`. README.md already mentions `herdr update --handoff`, and `herdr/scripts/herdr-image-doctor.sh` already prints stale-server guidance. Narrow this follow-up to making that existing guidance consistent and discoverable without duplicating it in a third place: mise manages the installed binary, while Herdr handoff or restart fixes stale runtime state.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Review the existing guidance in `README.md` and `herdr/scripts/herdr-image-doctor.sh`, then update only the minimum necessary locations to avoid duplicating the same advice in a third place.
- [x] #2 Docs or status-helper output clearly explain when to use `herdr update --handoff` or restart Herdr versus when to run `mise install` for the binary.
- [x] #3 The guidance covers the stale server/client mismatch shown by `herdr status --json`.
- [x] #4 Relevant markdown or shell validation is run, or the task records why manual documentation review is sufficient.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review the existing README and image-doctor guidance against installed Herdr help/status and mise configuration. 2. Clarify only the existing README stale-runtime bullet: distinguish mise-managed binary installation from server handoff/restart and client reattachment, using actual JSON field paths. Preserve TASK-23 plugin guidance and leave the doctor unchanged. 3. Validate the focused Markdown diff, relevant local links, and authoritative help/status evidence; record acceptance evidence and finalize TASK-26.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Reviewed README.md Kitty graphics guidance and herdr/scripts/herdr-image-doctor.sh diagnosis item 4. Installed `herdr update --help` says "Download and install the latest version" and `--handoff` says "Try live handoff after installing". Read-only `herdr status --json` confirms nested client.version=0.9.5, server.version=0.9.4, server.server_binary_stale=true, and client.binary under mise/installs/herdr/latest. mise/config.toml configures herdr = latest. README alone can supply the missing distinction without a third guidance location or shell changes.

AC1: Reviewed both existing guidance locations; changed only README.md lines 482-490. The doctor is byte-for-byte unchanged from base 2fc4e81afe9a659d59cc8ce2e3565ad0c73ac7e1; no third guidance location was added. AC2: Manual documentation review confirms mise install provisions the configured binary, server restart uses it, stale clients reattach, and herdr update --handoff downloads/installs latest then attempts handoff (not a runtime-only restart). AC3: README uses actual client.version, server.version, server.server_binary_stale fields and the TASK-22 0.9.4/0.9.1 stale-server example. AC4: Manual Markdown review is sufficient for this prose-only bullet edit; no shell/config/Actions code changed and no Markdown checker appears in .github/workflows (rg markdown|prettier|vale: No matches found). Existing nested-list formatting and nearby links were reviewed; relevant local README/AGENTS references exist. No live update, restart, or installation was run.

Validation commands and exact outputs (all run after explicit cd /Users/david/Developer/dotfiles-task-26): git diff --check: exit 0, no diagnostic output; wrapper printed "PASS: git diff --check". Python preservation/reference checks: "PASS: TASK-23 README plugin guidance unchanged"; "PASS: relevant README/AGENTS local references exist"; "PASS: image doctor unchanged; no third guidance location added". Python subprocess assertions using herdr update --help and herdr status --json: "PASS: installed herdr update --help confirms install plus attempted handoff"; "PASS: status JSON fields client.version=0.9.5, server.version=0.9.4, server.server_binary_stale=true"; "PASS: status client.binary resolves to a mise-managed Herdr installation". Source commit: 0c93ef29eea62ebf78bff884ff0bd27582ec71ed (required Co-authored-by and Copilot-Session trailers included). No executable changes need shell tests. Runtime was deliberately left unchanged; no follow-up work is required for this documentation task.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Clarified the existing README stale-Herdr bullet to separate mise-managed binary installation from running server/client refresh, explain update --handoff accurately, and name actual status JSON fields with the TASK-22 mismatch example. The doctor and TASK-23 plugin guidance remain unchanged. Documentation review, diff whitespace validation, reference/preservation checks, and read-only authoritative help/status assertions passed. No live updates, installs, restarts, push, PR, or merge performed.
<!-- SECTION:FINAL_SUMMARY:END -->
