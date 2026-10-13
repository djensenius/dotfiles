---
id: TASK-18
title: Remove unneeded Homebrew CLI packages
status: To Do
assignee: []
created_date: '2026-10-13 20:45'
labels: []
dependencies: []
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The macOS Brewfile still includes workstation-specific formulae that are not needed on the owner’s current setup. The owner specifically called out `transmission-cli` for removal and asked for additional candidates to consider after seeing a long Homebrew bundle run.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `mac/Brewfile` no longer installs `transmission-cli`.
- [ ] #2 Task notes record additional optional Homebrew removal candidates for owner follow-up, without removing packages beyond the owner-approved scope.
- [ ] #3 Relevant Brewfile/install checks pass or are reported with evidence.
<!-- AC:END -->
