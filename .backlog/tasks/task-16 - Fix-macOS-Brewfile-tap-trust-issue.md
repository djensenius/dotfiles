---
id: TASK-16
title: Fix macOS Brewfile tap trust issue
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-13 19:20'
updated_date: '2026-10-13 19:33'
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
1. Remove the deprecated homebrew/services tap from mac/Brewfile. 2. Declare arl/arl/gitmux trust directly in mac/Brewfile with Homebrew Brewfile metadata instead of a shell trust helper. 3. Keep brew bundle behavior unchanged and cover the Brewfile trust declaration/no deprecated services tap in install-mac tests.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Reviewer fix round rebuilt task-16-brewfile-trust on current origin/main without the unrelated TASK-17 backlog commits. The final branch removes the deprecated tap "homebrew/services" from mac/Brewfile, declares brew "arl/arl/gitmux", trusted: true with Homebrew Brewfile metadata, and leaves mac/install.sh without a shell brew trust helper. mac/tests/install-mac-test.sh now covers the Brewfile-native gitmux trust declaration, absence of the deprecated services tap, and that the brew section does not shell out to brew trust.

Validation passed after the fix-round commit:
- bash mac/tests/install-mac-test.sh -> ok install-mac tests passed
- bash mac/tests/brewfile-mise-lint.sh -> ok Brewfiles do not overlap mise-owned tools
- shellcheck mac/install.sh mac/tests/install-mac-test.sh mac/tests/brewfile-mise-lint.sh -> no diagnostics
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Removed the deprecated homebrew/services tap and now declares arl/arl/gitmux trust in mac/Brewfile with Homebrew Brewfile metadata. The macOS installer no longer carries a shell brew trust helper, and install-mac tests cover the Brewfile-native trust declaration plus no deprecated services tap. Verified with bash mac/tests/install-mac-test.sh, bash mac/tests/brewfile-mise-lint.sh, and shellcheck mac/install.sh mac/tests/install-mac-test.sh mac/tests/brewfile-mise-lint.sh.
<!-- SECTION:FINAL_SUMMARY:END -->
