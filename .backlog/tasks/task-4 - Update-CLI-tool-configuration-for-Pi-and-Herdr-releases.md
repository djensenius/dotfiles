---
id: TASK-4
title: Update CLI tool configuration for Pi and Herdr releases
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 16:54'
updated_date: '2026-10-01 16:58'
labels: []
dependencies: []
modified_files:
  - README.md
  - gitconfig
  - pi/agent-stack/install.sh
  - pi/agent-stack/mcp.json
  - pi/agent-stack/packages.txt
  - pi/agent-stack/settings.json
  - pi/agent-stack/tests/install-runtime.sh
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The local cli-update report shows Pi, Herdr, Pi extensions, and related CLI packages have moved forward. Pi 0.99.x now includes built-in MCP/codemode support, Herdr 0.9.x adds useful config options and fixes key handling, and accidental local shell/script edits should be normalized before committing the dotfiles configuration.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 fish config does not duplicate PATH entries already managed by fish/conf.d/10-paths.fish, including LM Studio and ~/.local/bin.
- [x] #2 gitconfig uses GitHub CLI credential helpers for github.com and gist.github.com without hard-coding an Apple Silicon Homebrew path.
- [x] #3 The accidental root-level slack-webhook.sh helper is not added to the repository, and any Slack webhook setup documentation or helper changes are omitted from this task.
- [x] #4 Pi agent-stack MCP configuration uses Pi built-in MCP config rather than pi-mcp-adapter, and docs/install code reference the new file and commands.
- [x] #5 Pi shared settings use the system theme unless the existing docs or config show a stronger reason to keep a fixed dark theme.
- [x] #6 Herdr 0.9 config changes are limited to useful non-conflicting settings; ctrl+s is not added as a prefix unless justified.
- [x] #7 Relevant shell, Herdr, agent-stack, YAML, and TOML validations are run and reported.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Replace the repo-managed Pi MCP adapter package/config with built-in MCP mcp.json wiring in pi/agent-stack/install.sh, packages.txt, and installer tests while preserving shared Playwright/context7 server merge behavior. 2. Update Pi README/settings docs for built-in MCP commands and system theme. 3. Add portable gh-based GitHub/Gist credential helpers to gitconfig without touching fish PATH or Herdr prefix config. 4. Run the targeted fish, Herdr, agent-stack, YAML, and status/security validations and commit the focused changes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented focused CLI configuration update: left fish/config.fish and Herdr prefix config unchanged; gitconfig now uses portable command -v gh credential helpers for github.com and gist.github.com; Pi agent-stack now merges built-in MCP config at mcp.json, no longer manages npm:pi-mcp-adapter, and shared Pi settings use theme system. Validation evidence: fish -n fish/config.fish (no output); herdr config check -> config: ok; node pi/agent-stack/tests/subagent-status.test.ts -> subagent-status tests passed; bash pi/agent-stack/tests/install-runtime.sh -> installer mise runtime tests passed; bash pi/agent-stack/tests/install-git-version.sh -> installer Git version tests passed; bash pi/agent-stack/tests/reviewer-git-security.sh -> reviewer-git security test passed ... side effects: none; yamllint . (no output); git config --file gitconfig --get-urlmatch credential.helper for github.com and gist.github.com returned the portable gh helper; grep confirmed no pi-mcp-adapter/mcp-adapter references remain in README.md or pi/agent-stack; git ls-files/test confirmed no slack-webhook.sh.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Updated TASK-4 CLI configuration: migrated repo-managed Pi MCP config from pi-mcp-adapter/mcp-adapter.json to built-in mcp.json, removed pi-mcp-adapter from managed packages, switched Pi shared theme to system, documented built-in MCP commands, and added portable gh credential helpers for GitHub and Gist. fish/config.fish and herdr/config.toml were not changed, preserving existing PATH and ctrl+a prefix behavior. Verified with fish, Herdr, agent-stack runtime/security/status tests, gitconfig URL matching, grep checks for removed adapter references, slack helper absence check, and yamllint.
<!-- SECTION:FINAL_SUMMARY:END -->
