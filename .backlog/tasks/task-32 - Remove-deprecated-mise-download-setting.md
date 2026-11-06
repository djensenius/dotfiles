---
id: TASK-32
title: Remove deprecated mise download setting
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-11-06T12:52:00Z'
updated_date: '2026-11-06T13:05:00Z'
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
- [x] #1 Neither mise configuration file sets the deprecated always_keep_download setting.
- [x] #2 The supported setting preserves the intended download-cache behavior and is accepted by mise.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Set download_cache = false in both mise configuration files to disable retention/reuse of finished downloads, matching the intent of always_keep_download = false. 2. Run focused TOML lint and validate each config via mise settings, confirming the effective value is false and no deprecation warning appears.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Replaced always_keep_download=false with download_cache=false in both mise config files. The installed mise 2026.11.0 settings documentation describes download_cache as a boolean (default true) that reuses finished downloads; false disables that cache, matching the intent not to retain finished downloads. tomllint mise/config.toml && tomllint mise/config-test.toml exited 0 with no output. With MISE_CONFIG_DIR set to /tmp/mise-task32-empty-config and MISE_CONFIG_FILE set to each file, mise settings download_cache printed false for each and emitted no warning. git diff --check exited 0 with no output. An initial non-isolated mise invocation warned because the main checkout mise/config.toml still has the deprecated setting; no change was made to the main checkout.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced deprecated always_keep_download=false with download_cache=false in both mise config files, preserving the intent not to keep finished downloads. The installed mise documentation confirms the supported boolean setting disables finished-download caching when false. Both TOML files linted successfully, and mise accepted each config with effective value false and no deprecation warning in isolated validation.
<!-- SECTION:FINAL_SUMMARY:END -->
