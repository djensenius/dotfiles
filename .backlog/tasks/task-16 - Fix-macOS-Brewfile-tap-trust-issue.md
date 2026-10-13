---
id: TASK-16
title: Fix macOS Brewfile tap trust issue
status: To Do
assignee: []
created_date: '2026-10-13 19:20'
labels: []
dependencies: []
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The macOS bootstrap currently fails during Homebrew bundle because `homebrew/services` is deprecated and empty. The same run warns that `arl/arl/gitmux` cannot be checked for updates until the formula is trusted, so the bootstrap should document or automate that trust step near the Brewfile usage.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `mac/Brewfile` no longer taps deprecated `homebrew/services`.
- [ ] #2 The macOS bootstrap includes an idempotent trust step for `arl/arl/gitmux` or clearly documents the required trust command before Homebrew bundle runs.
- [ ] #3 Relevant shell/YAML checks pass or are reported with evidence.
<!-- AC:END -->
