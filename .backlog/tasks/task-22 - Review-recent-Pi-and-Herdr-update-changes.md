---
id: TASK-22
title: Review recent Pi and Herdr update changes
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-15 13:50'
updated_date: '2026-10-15 13:55'
labels: []
dependencies: []
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Recent Pi and Herdr releases changed update flows and integration behavior. Herdr now exposes commands such as `herdr update` and `herdr plugin update`, while Pi 1.2.0 adds schema and extension-event changes. Review the current local versions, release notes, and dotfiles scripts/docs to identify small follow-up changes worth implementing without mixing them into TASK-21.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Review current local Pi and Herdr versions/update status and note any server/client mismatch or package-manager caveat
- [x] #2 Identify relevant recent Pi changes that affect this repo's settings, extensions, docs, or installer
- [x] #3 Identify relevant recent Herdr changes that affect this repo's config, plugin updater, docs, or installer
- [x] #4 Create follow-up Backlog tasks for implementation candidates or explicitly record that no repo changes are needed
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Use the scout artifact and local CLI output to summarize Pi/Herdr update status, including the stale Herdr server/client mismatch. 2. Create bounded follow-up Backlog tasks for each concrete implementation candidate instead of editing source/config files. 3. Record created task IDs, check TASK-22 acceptance criteria with evidence, add a final summary, and set Done as the last task change.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Local status evidence: `pi --version` returned `1.2.0`; `herdr --version` returned `herdr 0.9.4`; `mise which herdr` returned `/Users/david/.local/share/mise/installs/herdr/latest/herdr`; `herdr status --json` reported client version 0.9.4, running server version 0.9.1, `compatible=true`, `restart_needed=false`, and `server_binary_stale=true`. This confirms the package-manager caveat that mise owns the installed Herdr binary while the stale server is a Herdr runtime handoff/restart issue.

Scout artifact evidence: Herdr plugin refresh in `herdr/scripts/herdr-cli-update.sh` still uses `herdr plugin install <plugin> --yes`; README already mentions `herdr update --handoff`; Pi 1.2.0 follow-up candidates are missing `$schema` annotations in `ai-tools/settings.json`, `ai-tools/mcp.json`, and `ai-tools/catppuccin-footer.json`, plus lifecycle listener compatibility for `pi.on("agent_start", ...)` in `ai-tools/extensions/subagent-status.ts`.

Created follow-up tasks: TASK-23 `Use Herdr plugin update in the plugin refresh flow`; TASK-24 `Add Pi 1.2 schema annotations to AI tool JSON configs`; TASK-25 `Audit Pi 1.2 extension lifecycle listener compatibility`; TASK-26 `Clarify stale Herdr server and client update guidance`.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Finalized TASK-22 as a research/backlog task without source/config edits. Verified local Pi/Herdr versions and Herdr server/client mismatch with CLI output, used the scout artifact to identify Pi and Herdr repo impacts, and created TASK-23 through TASK-26 for the concrete implementation candidates.
<!-- SECTION:FINAL_SUMMARY:END -->
