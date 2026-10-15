---
id: TASK-24
title: Add Pi 1.2 schema annotations to AI tool JSON configs
status: To Do
assignee: []
created_date: '2026-10-15 13:54'
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
