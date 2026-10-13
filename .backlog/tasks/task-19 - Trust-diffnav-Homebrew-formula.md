---
id: TASK-19
title: Trust diffnav Homebrew formula
status: To Do
assignee: []
created_date: '2026-10-13 21:30'
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
