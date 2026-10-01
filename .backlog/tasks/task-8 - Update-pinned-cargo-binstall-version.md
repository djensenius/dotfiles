---
id: TASK-8
title: Update pinned cargo-binstall version
status: In Progress
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
- [ ] #1 mise/config.toml pins cargo-binstall to the intended newer released version
- [ ] #2 TOML validation is run for the mise config change and reported
- [ ] #3 No unrelated stashed PATH, credential-helper, or Slack webhook helper changes are included
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Update the cargo-binstall pin in mise/config.toml to the released 1.24.0 version discovered in the discarded stash, then run the repository TOML validation and ensure no unrelated stash changes are included.
<!-- SECTION:PLAN:END -->
