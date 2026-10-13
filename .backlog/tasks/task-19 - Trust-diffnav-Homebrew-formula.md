---
id: TASK-19
title: Trust diffnav Homebrew formula
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-13 21:30'
updated_date: '2026-10-13 21:31'
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
1. Compare existing Brewfile trust metadata for arl/arl/gitmux and mirror that pattern for dlvhdr/formulae/diffnav. 2. Update mac install tests only as needed to assert the diffnav trust declaration. 3. Run the mac Brewfile/install checks and finalize TASK-19 with evidence.
<!-- SECTION:PLAN:END -->
