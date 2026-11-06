---
id: TASK-32
title: Remove deprecated mise download setting
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-11-06T12:52:00Z'
updated_date: '2026-11-06T13:08:00Z'
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
1. Remove the incorrect download_cache=false replacement and its adjacent comment from both mise configs; leave all other cache settings unchanged. 2. Load each config in isolation with mise and verify no always_keep_download warning and default enabled download_cache behavior. 3. Run tomllint on both files and git diff --check; record evidence, finalize task state, and create a new logical fix commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Replaced always_keep_download=false with download_cache=false in both mise config files. The installed mise 2026.11.0 settings documentation describes download_cache as a boolean (default true) that reuses finished downloads; false disables that cache, matching the intent not to retain finished downloads. tomllint mise/config.toml && tomllint mise/config-test.toml exited 0 with no output. With MISE_CONFIG_DIR set to /tmp/mise-task32-empty-config and MISE_CONFIG_FILE set to each file, mise settings download_cache printed false for each and emitted no warning. git diff --check exited 0 with no output. An initial non-isolated mise invocation warned because the main checkout mise/config.toml still has the deprecated setting; no change was made to the main checkout.

Fix round requested after commit 7837e66a4ca3cff9f04c136b66d7d90fa518caa2 was blocked: download_cache=false disables normal cache reuse and is not equivalent to always_keep_download=false. The previous plan, evidence interpretation, and final summary are superseded by this correction. Remove the override rather than replacing the obsolete setting.

Correction implemented: removed download_cache=false and its adjacent explanatory comment from both TOMLs, leaving always_keep_install and all other cache settings unchanged. Neither file contains always_keep_download or download_cache. For each file, isolated MISE_CONFIG_DIR plus MISE_CONFIG_FILE pointing to that repository file gave mise settings download_cache = true and empty stderr (MISE_DOWNLOAD_CACHE and MISE_ALWAYS_KEEP_DOWNLOAD environment overrides removed). tomllint mise/config.toml: exit 0; tomllint mise/config-test.toml: exit 0. The latter invocation via the mise shim emitted the existing unrelated settings.disable_default_shorthands unknown-field warning; left unchanged as out of scope. An initial validation harness incorrectly required completely silent linter stderr and failed on that unrelated warning; subsequent lint checks recorded actual successful exit codes without hiding stderr. A diagnostic mise which tomllint failed because tomllint is not active in that isolated config; no tool installation or config expansion was performed. git diff --check: exit 0 (no output). Both acceptance criteria are verified by absence of overrides and successful runtime default=true checks; supported default behavior is preserved without adding a replacement setting.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Removed the incorrect download_cache=false replacement and adjacent comment from both mise configs. The deprecated always_keep_download setting remains absent; normal supported download-cache behavior is restored through the default rather than an override. Both configs load with download_cache=true and no stderr from mise settings, both pass tomllint, and git diff --check passes. The pre-existing disable_default_shorthands warning emitted by the lint shim for config-test.toml is unrelated and unchanged.
<!-- SECTION:FINAL_SUMMARY:END -->
