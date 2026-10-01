---
id: TASK-9
title: Adopt Pi 1.0 agent-stack config refinements
status: To Do
assignee: []
created_date: '2026-10-01 19:27'
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
- [ ] #1 Shared Pi settings keep fullscreen/system defaults and add the Pi 1.0 quiet startup header behavior if supported by Pi 1.0 settings
- [ ] #2 Repository-managed MCP server entries include useful descriptions for the shared Playwright and Context7 servers
- [ ] #3 README documents any Pi 1.0-specific shared defaults that were added or confirms why other 1.0 features remain user/account-specific
- [ ] #4 Agent-stack runtime validation passes after the config changes
<!-- AC:END -->
