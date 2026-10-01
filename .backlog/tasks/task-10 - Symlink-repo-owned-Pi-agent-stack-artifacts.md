---
id: TASK-10
title: Symlink repo-owned Pi agent-stack artifacts
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 22:05'
updated_date: '2026-10-01 22:09'
labels: []
dependencies: []
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Pi stores mutable user state under ~/.pi/agent, so settings.json and mcp.json need merge-based handling. However several agent-stack artifacts are fully repo-owned extension/profile/config files, and those should behave like dotfiles: after the installer creates the links once, a later git pull should update them without rerunning the installer.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 install-agent-stack links repo-owned Pi extension and agent profile files into ~/.pi/agent instead of copying them
- [x] #2 settings.json and mcp.json remain merge-based and are not symlinked
- [x] #3 The installer safely replaces prior repo-owned copied files or symlinks while preserving non-repo user files
- [x] #4 Runtime tests cover symlink creation, rerun behavior, and local-state preservation for Pi agent-stack artifacts
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Update install-agent-stack to symlink only fully repo-owned Pi agent-stack artifacts (extensions/profiles and possibly footer config), leave settings.json and mcp.json merge-based, add runtime tests for creation/rerun/non-repo preservation, and validate the agent-stack installer tests.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented symlink handling for repo-owned Pi agent-stack artifacts: extensions, profiles, and catppuccin-footer.json now link from pi/agent-stack into $PI_CODING_AGENT_DIR (default ~/.pi/agent). settings.json, mcp.json, and subagent config remain merge-based. Existing matching copied files are converted to links; differing local files are moved aside as .backup before linking.

Validation passed after code commit afbb905: bash pi/agent-stack/tests/install-runtime.sh -> installer mise runtime tests passed; node pi/agent-stack/tests/subagent-status.test.ts -> subagent-status tests passed; yamllint . -> no output; git diff --check 0c24a37..HEAD -> no output.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Linked repo-owned Pi agent-stack extensions, profiles, and catppuccin-footer.json into ~/.pi/agent / $PI_CODING_AGENT_DIR; kept settings.json, mcp.json, and subagent config merge-based; backed up non-matching existing files to .backup before linking; documented the behavior. Verified with install-runtime, subagent-status tests, yamllint, and git diff --check.
<!-- SECTION:FINAL_SUMMARY:END -->
