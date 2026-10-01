---
id: TASK-8
title: Update pinned cargo-binstall version
status: To Do
assignee: []
created_date: '2026-10-01 19:21'
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
