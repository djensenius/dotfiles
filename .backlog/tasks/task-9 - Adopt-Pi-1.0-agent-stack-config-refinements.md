---
id: TASK-9
title: Adopt Pi 1.0 agent-stack config refinements
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 19:27'
updated_date: '2026-10-01 19:29'
labels: []
dependencies: []
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Pi 1.0.0 shipped after the recent agent-stack updates. The release notes show most big items are already covered here (system theme, fullscreen TUI, built-in MCP/codemode), but two safe repo-managed defaults look useful: quiet startup header mode for less noisy launches and MCP server descriptions so Pi 1.0 can summarize/search the shared servers better.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Shared Pi settings keep fullscreen/system defaults and add the Pi 1.0 quiet startup header behavior if supported by Pi 1.0 settings
- [x] #2 Repository-managed MCP server entries include useful descriptions for the shared Playwright and Context7 servers
- [x] #3 README documents any Pi 1.0-specific shared defaults that were added or confirms why other 1.0 features remain user/account-specific
- [x] #4 Agent-stack runtime validation passes after the config changes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Add the safe Pi 1.0 shared defaults: quietStartup "header" in pi/agent-stack/settings.json and descriptions on the two shared MCP servers. Update README and runtime tests to verify the merged settings/descriptions while leaving Radius/image generation/account-specific features as user choices.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added Pi 1.0 shared config refinements: pi/agent-stack/settings.json now sets quietStartup to "header" while keeping system theme and fullscreen TUI; pi/agent-stack/mcp.json now describes the shared Playwright and Context7 MCP servers for Pi 1.0 server summaries/tool search. README documents that Radius sign-in, codemode image generation, and custom MCP OAuth metadata are user/account/server-specific rather than forced shared defaults. Validation: jq empty pi/agent-stack/settings.json pi/agent-stack/mcp.json; bash pi/agent-stack/tests/install-runtime.sh -> installer mise runtime tests passed; yamllint . -> no output; git diff --check -> no output.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Adopted two safe Pi 1.0 config defaults: quietStartup "header" and MCP server descriptions for Playwright/Context7. Documented why other Pi 1.0 features remain user-specific and verified JSON, agent-stack runtime tests, YAML lint, and whitespace checks.
<!-- SECTION:FINAL_SUMMARY:END -->
