---
id: TASK-19
title: Trust diffnav Homebrew formula
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-13 21:30'
updated_date: '2026-10-13 21:34'
labels: []
dependencies: []
modified_files:
  - mac/Brewfile
  - mac/tests/install-mac-test.sh
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The macOS Homebrew bundle now fails on `dlvhdr/formulae/diffnav` because Homebrew refuses to load formulae from untrusted taps. TASK-16 added Brewfile-native trust for gitmux; apply the same declarative trust approach to diffnav.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 mac/Brewfile declares formula-specific trust for dlvhdr/formulae/diffnav, influxdata/tap/influxctl, morantron/tmux-fingers/tmux-fingers, timescam/tap/tuios, djensenius/tap/telephone-booth-operator-cli, and djensenius/tap/worldcup26.
- [x] #2 Relevant Brewfile/install tests pass or are reported with evidence.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Mirror existing Brewfile-native trusted metadata for each third-party formula Homebrew may refuse: arl/arl/gitmux remains trusted, add trusted: true to dlvhdr/formulae/diffnav, influxdata/tap/influxctl, morantron/tmux-fingers/tmux-fingers, timescam/tap/tuios, djensenius/tap/telephone-booth-operator-cli, and djensenius/tap/worldcup26. 2. Keep trust formula-specific rather than broad tap-level commands. 3. Update install tests to assert the trusted Brewfile declarations and run the requested mac checks.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added formula-specific Brewfile trusted: true metadata for dlvhdr/formulae/diffnav plus influxdata/tap/influxctl, morantron/tmux-fingers/tmux-fingers, timescam/tap/tuios, djensenius/tap/telephone-booth-operator-cli, and djensenius/tap/worldcup26. Preserved the existing arl/arl/gitmux trust declaration and kept trust on formula entries instead of adding broad tap trust commands. Validation: bash mac/tests/install-mac-test.sh -> ok install-mac tests passed; bash mac/tests/brewfile-mise-lint.sh -> ok Brewfiles do not overlap mise-owned tools; shellcheck mac/tests/install-mac-test.sh -> no diagnostics.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented formula-specific Brewfile trust metadata for the Homebrew formulae that may be refused from third-party taps, and updated install-mac tests to assert those declarations. Verified with the install-mac test suite, Brewfile/mise lint, and shellcheck on the changed shell test.
<!-- SECTION:FINAL_SUMMARY:END -->
