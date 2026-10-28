---
id: TASK-24
title: Add Pi 1.2 schema annotations to AI tool JSON configs
status: In Progress
assignee:
  - '@copilot-worker'
created_date: 2026-10-15 13:54
updated_date: '2026-10-28T18:31:00Z'
labels: []
dependencies: []
modified_files:
  - ai-tools/settings.json
  - ai-tools/mcp.json
  - ai-tools/catppuccin-footer.json
type: task
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-22 found Pi 1.2.0 on PATH and repo-owned AI tool JSON files without `$schema` annotations. Adding schemas should wait until stable Pi schema URLs or schema IDs are confirmed so the configs improve editor validation without pinning guessed locations.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Stable Pi schema URL(s) or schema IDs are confirmed from Pi documentation, release notes, or the installed runtime before any JSON edits.
- [ ] #2 `ai-tools/settings.json`, `ai-tools/mcp.json`, and `ai-tools/catppuccin-footer.json` include correct `$schema` annotations where Pi supports them, with unsupported files explicitly noted.
- [ ] #3 JSON syntax remains valid and any relevant schema or lint validation output is recorded.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Confirm the installed Pi identity and published settings schema against official release/runtime documentation; inspect the matching upstream schema generator and MCP reader, and installed footer source for per-file support. Record authoritative URLs and installed file:line evidence before editing JSON.
2. Add only supported $schema annotations; explicitly document unsupported MCP/footer files in task notes. Add a focused installer regression assertion only if needed to cover preservation of the annotation through merging.
3. Validate all three JSON files, validate settings against the published schema without transmitting config content, and run the existing isolated installer runtime tests. Record exact outputs, finalize only evidenced criteria, and commit TASK-24 changes with the requested trailers.
<!-- SECTION:PLAN:END -->
