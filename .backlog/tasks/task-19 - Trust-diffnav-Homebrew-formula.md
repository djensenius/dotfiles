---
id: TASK-19
title: Trust diffnav Homebrew formula
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-13 21:30'
updated_date: '2026-10-13 21:32'
labels: []
dependencies: []
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The macOS Homebrew bundle now fails on `dlvhdr/formulae/diffnav` because Homebrew refuses to load formulae from untrusted taps. TASK-16 added Brewfile-native trust for gitmux; apply the same declarative trust approach to diffnav.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `mac/Brewfile` declares trust for `dlvhdr/formulae/diffnav`.
- [ ] #2 Relevant Brewfile/install tests pass or are reported with evidence.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Mirror existing Brewfile-native trusted metadata for each third-party formula Homebrew may refuse: arl/arl/gitmux remains trusted, add trusted: true to dlvhdr/formulae/diffnav, influxdata/tap/influxctl, morantron/tmux-fingers/tmux-fingers, timescam/tap/tuios, djensenius/tap/telephone-booth-operator-cli, and djensenius/tap/worldcup26. 2. Keep trust formula-specific rather than broad tap-level commands. 3. Update install tests to assert the trusted Brewfile declarations and run the requested mac checks.
<!-- SECTION:PLAN:END -->
