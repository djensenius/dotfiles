---
id: TASK-8
title: Update pinned cargo-binstall version
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 19:21'
updated_date: '2026-10-01 19:21'
labels: []
dependencies: []
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The pre-merge local stash included a mise/config.toml bump from cargo-binstall 1.17.9 to 1.24.0. The PATH and credential-helper stash entries were already superseded by repo-managed config, and the Slack helper should not be committed as an accidental root script, but the cargo-binstall pin looks like a legitimate toolchain update worth applying deliberately.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 mise/config.toml pins cargo-binstall to the intended newer released version
- [x] #2 TOML validation is run for the mise config change and reported
- [x] #3 No unrelated stashed PATH, credential-helper, or Slack webhook helper changes are included
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Update the cargo-binstall pin in mise/config.toml to the released 1.24.0 version discovered in the discarded stash, then run the repository TOML validation and ensure no unrelated stash changes are included.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Updated mise/config.toml cargo-binstall pin from 1.17.9 to released version 1.24.0. Validation: python3 -m pip install tomllint completed successfully; for f in **/*.toml; do [ -f "$f" ] && tomllint "$f"; done completed with no output. No stashed fish PATH, git credential helper, or slack-webhook.sh changes were applied.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Bumped the mise cargo-binstall pin to 1.24.0 and validated all TOML files with tomllint. Left the unrelated discarded stash changes out.
<!-- SECTION:FINAL_SUMMARY:END -->
