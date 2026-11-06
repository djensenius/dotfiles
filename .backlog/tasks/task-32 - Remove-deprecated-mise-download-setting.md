---
id: TASK-32
title: Remove deprecated mise download setting
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-11-06T12:52:00Z'
updated_date: '2026-11-06T12:56:00Z'
labels: []
dependencies: []
type: bug
ordinal: 28000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mise warns that `setting.always_keep_download` is deprecated and will be removed in 2027.11.0. Update the repository configurations so the warning is eliminated while preserving the intended download-cache behavior.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Neither mise configuration file sets the deprecated always_keep_download setting.
- [ ] #2 The supported setting preserves the intended download-cache behavior and is accepted by mise.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Set download_cache = false in both mise configuration files to disable retention/reuse of finished downloads, matching the intent of always_keep_download = false. 2. Run focused TOML lint and validate each config via mise settings, confirming the effective value is false and no deprecation warning appears.
<!-- SECTION:PLAN:END -->
