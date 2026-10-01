---
id: TASK-5
title: Fix pi-memctx host extension dependency warning
status: To Do
assignee: []
created_date: '2026-10-01 17:16'
labels: []
dependencies: []
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The Pi extension loader warns that host-provided extension packages must declare shared runtime packages in peerDependencies with a "*" range. The installed pi-memctx package currently declares @sinclair/typebox under dependencies, which can bypass the extension loader and create duplicate runtime modules.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Pi no longer emits the warning for /Users/david/.pi/agent/npm/node_modules/pi-memctx/package.json declaring @sinclair/typebox in dependencies
- [ ] #2 The relevant package manifest declares @sinclair/typebox in peerDependencies with range "*"
- [ ] #3 Any lockfile or generated package metadata affected by the manifest change is updated consistently
<!-- AC:END -->
