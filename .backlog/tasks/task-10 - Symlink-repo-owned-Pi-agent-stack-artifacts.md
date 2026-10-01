---
id: TASK-10
title: Symlink repo-owned Pi agent-stack artifacts
status: To Do
assignee: []
created_date: '2026-10-01 22:05'
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
- [ ] #1 install-agent-stack links repo-owned Pi extension and agent profile files into ~/.pi/agent instead of copying them
- [ ] #2 settings.json and mcp.json remain merge-based and are not symlinked
- [ ] #3 The installer safely replaces prior repo-owned copied files or symlinks while preserving non-repo user files
- [ ] #4 Runtime tests cover symlink creation, rerun behavior, and local-state preservation for Pi agent-stack artifacts
<!-- AC:END -->
