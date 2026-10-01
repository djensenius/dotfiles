---
id: TASK-5
title: Fix pi-memctx host extension dependency warning
status: Done
assignee:
  - '@pi'
created_date: '2026-10-01 17:16'
updated_date: '2026-10-01 17:22'
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
- [x] #1 Pi no longer emits the warning for /Users/david/.pi/agent/npm/node_modules/pi-memctx/package.json declaring @sinclair/typebox in dependencies
- [x] #2 The relevant package manifest declares @sinclair/typebox in peerDependencies with range "*"
- [x] #3 Any lockfile or generated package metadata affected by the manifest change is updated consistently
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Apply a local installed-package workaround because pi-memctx source is not in this checkout: move @sinclair/typebox from dependencies to peerDependencies with range "*" in the installed package manifest and mirror the change in the npm install-tree lock metadata. Validate by direct manifest/lock assertions and user confirmation that the Pi warning no longer appears.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Local workaround applied to /Users/david/.pi/agent/npm/node_modules/pi-memctx/package.json and /Users/david/.pi/agent/npm/node_modules/.package-lock.json. Direct jq validation returned true for the manifest, Python validation reported the lock entry ok, and the owner confirmed the warning is gone after reload. Durable upstream fix still belongs in https://github.com/weauratech/pi-memctx.git because reinstall can overwrite local installed state.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Applied a local installed-state workaround for pi-memctx by declaring @sinclair/typebox as a peerDependency with range "*" in the installed package manifest and matching lock metadata. Verified with jq/Python assertions and owner confirmation that the warning is gone; upstream/reinstall-safe fix remains a separate concern in https://github.com/weauratech/pi-memctx.git.
<!-- SECTION:FINAL_SUMMARY:END -->
