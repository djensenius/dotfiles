---
id: TASK-16
title: Fix macOS Brewfile tap trust issue
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-13 19:20'
updated_date: '2026-10-13 19:24'
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
- [x] #1 `mac/Brewfile` no longer taps deprecated `homebrew/services`.
- [x] #2 The macOS bootstrap includes an idempotent trust step for `arl/arl/gitmux` or clearly documents the required trust command before Homebrew bundle runs.
- [x] #3 Relevant shell/YAML checks pass or are reported with evidence.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Remove the deprecated homebrew/services tap from mac/Brewfile. 2. Add a small Homebrew formula trust helper and call it for arl/arl/gitmux before any brew bundle check/install in the brew section, keeping --check/--dry-run read-only. 3. Extend install-mac tests with fake brew trust coverage and run the requested checks.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Brewfile trust fix and verified with:
- bash mac/tests/install-mac-test.sh -> ok install-mac tests passed
- bash mac/tests/brewfile-mise-lint.sh -> ok Brewfiles do not overlap mise-owned tools
- shellcheck mac/install.sh mac/tests/install-mac-test.sh mac/tests/brewfile-mise-lint.sh -> no diagnostics (ShellCheck 0.11.0)
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Removed the deprecated homebrew/services tap, added an idempotent arl/arl/gitmux Homebrew formula trust check before brew bundle in mac/install.sh, and covered the trust ordering/no-op behavior in mac/tests/install-mac-test.sh. Verified with install-mac tests, Brewfile/mise lint, and shellcheck.
<!-- SECTION:FINAL_SUMMARY:END -->
