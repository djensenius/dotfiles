---
id: TASK-28
title: Move Herdr idle battery percentage after hearts
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-15 15:18'
updated_date: '2026-10-15 15:21'
labels: []
dependencies: []
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-27 made the Herdr tab-bar show battery percentage when no update counts are present, but 80% 󱐮 󰋑 󰛞  renders the percentage before the hearts. The desired display is hearts first with the percentage beside/after them, while the update-count case remains compact hearts-only.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 When no update counts render, the Herdr tab-bar battery display shows hearts followed by the percentage
- [x] #2 When any update count renders, the display remains compact hearts-only before the counts
- [x] #3 The tab-bar path remains cache-read-only and does not trigger package checks
- [x] #4 Tests cover no-count hearts-then-percent output and count-present hearts-only output
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Normalize the idle battery string in herdr-status-report.sh so percent-leading battery_hearts output renders as hearts followed by percent while compact/count-present output stays unchanged.
2. Update the Herdr CLI status test fixture and assertions for idle hearts-then-percent and count-present hearts-only behavior.
3. Run bash syntax, shellcheck, git diff whitespace, and the Herdr CLI update test before finalizing TASK-28.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented in 8bd71b8899bd82ff85413761a1e411b2b698b6ee: idle tab-bar rendering now passes battery_hearts percent-leading output through battery_percent_after_hearts, producing hearts followed by percent only for the no-count path. The count-present path still calls battery_status -1 and render_tab_bar still gathers updates exclusively through manager_count() cache reads before formatting battery output. Updated herdr/tests/herdr-cli-update-test.sh to assert no-count "♥♥♡♡♡ 80%", count-present "♡♡♡♡♡  π 1  H 2", and absence of package-checker marker files after both renders. README now says the idle percentage appears after the hearts.
Validation evidence: bash -n herdr/scripts/herdr-status-report.sh herdr/tests/herdr-cli-update-test.sh passed with no output; shellcheck herdr/scripts/herdr-status-report.sh herdr/tests/herdr-cli-update-test.sh passed with no output; git diff --check passed with no output; bash herdr/tests/herdr-cli-update-test.sh printed Herdr CLI cache snapshot tests passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented Herdr idle battery ordering in 8bd71b8899bd82ff85413761a1e411b2b698b6ee: the no-count tab-bar path now normalizes percent-leading battery_hearts output to hearts followed by percent, while count-present rendering remains compact hearts-only from battery_status -1. The tab-bar renderer remains cache-read-only for package counts, and the Herdr CLI cache/render test now covers idle hearts-then-percent, count-present hearts-only, and no package-checker invocation. Verified with bash -n, shellcheck, git diff --check, and bash herdr/tests/herdr-cli-update-test.sh.
<!-- SECTION:FINAL_SUMMARY:END -->
