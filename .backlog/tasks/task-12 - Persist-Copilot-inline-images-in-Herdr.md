---
id: TASK-12
title: Persist Copilot inline images in Herdr
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-04 19:38'
updated_date: '2026-10-04 19:40'
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
- [ ] #1 Tracked Fish configuration exports COPILOT_INLINE_IMAGES_HERDR=1 for new interactive environments
- [ ] #2 The setting is installed on both the primary workstation and Raspberry Pi through the repository-supported setup paths without unnecessary duplicate configuration
- [ ] #3 Fish configuration validation confirms the variable is available in a fresh shell
<!-- AC:END -->
