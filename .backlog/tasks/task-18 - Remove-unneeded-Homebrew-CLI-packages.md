---
id: TASK-18
title: Remove unneeded Homebrew CLI packages
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-13 20:45'
updated_date: '2026-10-13 20:47'
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
- [x] #1 `mac/Brewfile` no longer installs `transmission-cli`.
- [x] #2 Task notes record additional optional Homebrew removal candidates for owner follow-up, without removing packages beyond the owner-approved scope.
- [x] #3 Relevant Brewfile/install checks pass or are reported with evidence.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Remove only the owner-approved transmission-cli entry from mac/Brewfile. 2. Record optional follow-up Homebrew removal candidates in task notes without changing them. 3. Run Brewfile/install checks and finalize acceptance criteria with evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Removed only the owner-approved transmission-cli Brewfile entry. Optional owner follow-up candidates noted for consideration only (not removed): minidlna; postgis; postgresql@15 if the older server is no longer needed alongside postgresql@18; redis; telnet; azure-cli and influxdata/influx CLIs; embedded/mobile/game utilities cc65, dex2jar, dtc, esphome, jadx, mupen64plus, rgbds, and tuios.

Validation passed: grep confirmed transmission-cli absent; bash mac/tests/brewfile-mise-lint.sh printed 'ok Brewfiles do not overlap mise-owned tools'; bash mac/tests/install-mac-test.sh printed 'ok install-mac tests passed'.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Removed only transmission-cli from mac/Brewfile; left all other formulae intact and recorded optional follow-up removal candidates in notes. Verified absence with grep and passed brewfile-mise-lint plus install-mac tests.
<!-- SECTION:FINAL_SUMMARY:END -->
