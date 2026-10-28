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
2. Add only supported $schema annotations; explicitly document unsupported MCP/footer files in task notes. Add a focused installer regression assertion to cover preservation of the annotation through merging.
3. Validate all three JSON files, validate settings against the published schema without transmitting config content, and run the existing isolated installer runtime tests. Record exact outputs, finalize only evidenced criteria, and commit TASK-24 changes with the requested trailers.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Pre-edit authoritative evidence (2026-10-28):
- `command -v pi` => `/Users/david/.local/share/mise/installs/pi/latest/pi/pi`; `pi --version` => `1.4.0`. Installed `package.json:2-3,111-115` identifies `@earendil-works/pi-coding-agent` and `https://github.com/earendil-works/pi.git` (not an assumed badlogic fork). Repo `mise/config.toml:12` tracks latest.
- Installed `/Users/david/.local/share/mise/installs/pi/latest/pi/docs/settings.md:5` explicitly instructs adding `"$schema": "https://pi.dev/schemas/settings.schema.json"`. Installed `CHANGELOG.md:105-117` documents publication in Pi 1.2.0. Matching v1.2.0 docs confirmed via GitHub API: https://github.com/earendil-works/pi/blob/v1.2.0/packages/coding-agent/docs/settings.md#L5 .
- Read-only GET https://pi.dev/schemas/settings.schema.json succeeded: `$id` = `https://pi.dev/schemas/settings.schema.json`, draft = `https://json-schema.org/draft/2020-12/schema`, explicit `$schema` string property, `additionalProperties: true` (so extension-owned `subagents` remains allowed). https://github.com/earendil-works/pi/blob/v1.4.0/packages/coding-agent/src/core/settings-schema.ts#L206-L208 explicitly supports the annotation; #L453 permits extension settings.
- MCP: no published Pi MCP config schema in the release inventory. Both v1.2.0 and v1.4.0 `packages/coding-agent/schemas` list only `keybindings.schema.json`, `models.schema.json`, `settings.schema.json`, `theme.schema.json`. The exhaustive generator artifact list is https://github.com/earendil-works/pi/blob/v1.4.0/packages/coding-agent/scripts/generate-schemas.ts#L32-L59 . Installed `docs/mcp.md:30-86` documents the `mcpServers` shape and runtime rules, not a schema URL. Leave `ai-tools/mcp.json` unannotated; settings/theme schemas do not describe MCP.
- Footer: installed `/Users/david/.pi/agent/npm/node_modules/pi-catppuccin-footer/package.json:2-3` = `pi-catppuccin-footer` 0.1.2; its files list (lines 15-21) ships no schema. `extensions/catppuccin-footer.ts:38-53` defines a TS-only FooterConfig interface and `:160-167` parses JSON with a type assertion, not schema validation. README configuration at `README.md:87-105` has no schema reference; a scoped search found no schema file/reference in the installed package. Leave `ai-tools/catppuccin-footer.json` unannotated: it is extension config, not a Pi theme, and the published theme schema is inapplicable.
No JSON edits preceded this confirmation. Only settings has a confirmed supported schema.
<!-- SECTION:NOTES:END -->
