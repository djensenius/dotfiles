---
id: TASK-12
title: Persist Copilot inline images in Herdr
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-04 19:38'
updated_date: '2026-10-04 19:53'
labels: []
dependencies: []
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Copilot CLI requires COPILOT_INLINE_IMAGES_HERDR=1 to render attachments inside Herdr even when Herdr Kitty graphics are enabled. The current successful test only changed a live Fish environment, so new shells and machines—including Raspberry Pi installations—do not reliably inherit the opt-in.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Tracked Fish configuration exports COPILOT_INLINE_IMAGES_HERDR=1 for new interactive environments
- [x] #2 The setting is installed on both the primary workstation and Raspberry Pi through the repository-supported setup paths without unnecessary duplicate configuration
- [x] #3 Fish configuration validation confirms the variable is available in a fresh shell
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add COPILOT_INLINE_IMAGES_HERDR=1 to fish/conf.d/00-env.fish, the shared session-scoped environment file loaded by Fish. 2. Validate Fish syntax and a fresh Fish process, then exercise the smallest link checks proving the Codespaces/local, macOS, and Raspberry Pi installers all consume the shared fish/ directory without duplicate Pi-only configuration.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented the opt-in once in fish/conf.d/00-env.fish, matching the shared session-scoped environment convention. Verification passed: Fish syntax checks; fresh Fish output COPILOT_INLINE_IMAGES_HERDR=1; normal/Codespaces, macOS links-only, and Raspberry Pi links-only installs each resolved ~/.config/fish to this worktree shared fish/ directory; a fresh Fish through the Pi-created link also returned 1; repository search found exactly one tracked definition.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added the exported COPILOT_INLINE_IMAGES_HERDR=1 opt-in to the shared Fish conf.d environment file so every supported installation path inherits it without Pi-specific duplication. Verified Fish syntax and fresh-shell export, exercised the normal/Codespaces link function plus macOS and Raspberry Pi link installers against isolated project-local homes, and confirmed all linked the shared fish/ directory.
<!-- SECTION:FINAL_SUMMARY:END -->
