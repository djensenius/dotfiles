---
id: TASK-27
title: Show battery percent when Herdr status has no updates
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-15 14:47'
updated_date: '2026-10-15 14:51'
labels: []
dependencies: []
ordinal: 25000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The Herdr tab-bar status currently keeps battery hearts compact to avoid Kitty/rendering width issues when package update counts are present. When there are no software-update counts, that right-side status area has enough room to show useful battery percentage next to the hearts without worsening the crowded update case.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 When any software-update count is rendered, the Herdr tab-bar battery display remains the compact hearts-only form
- [x] #2 When no software-update counts are rendered, the battery display includes percentage next to the hearts
- [x] #3 The status helper remains fast and uses cached package counts rather than triggering package checks from the tab-bar path
- [x] #4 Tests or scripted checks cover both update-count-present and no-update-count rendering cases
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the Herdr tab-bar renderer and tests to keep the change limited to battery argument selection based on cached update-count output.
2. Update the status helper so render_tab_bar reads cached manager counts first, uses compact battery hearts when any count will be shown, and uses battery_hearts --threshold 1 when no counts will be shown.
3. Update the Herdr CLI/tab-bar test stub to assert both no-update percent output and update-count compact output without invoking package checks.
4. Run the targeted Herdr test and shell syntax checks, then record evidence, check acceptance criteria, and finish the task.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation completed in commit 31b3044: render_tab_bar now reads cached manager counts before choosing battery flags, calls battery_hearts --threshold 0 when any update count is shown, and calls battery_hearts --threshold 1 when no counts are shown. The tab-bar path still only uses manager_count() cache reads; the test PATH includes failing brew/npm/pi/pip/cargo/go/mise/herdr command stubs to prove render_tab_bar does not invoke package checkers.
Validation: battery_hearts --max-hearts 5 --threshold 1 --cmd "printf '80%%; discharging\\n'" produced a percent-prefixed output; --threshold 0 omitted a percent prefix. bash -n herdr/scripts/herdr-status-report.sh herdr/tests/herdr-cli-update-test.sh passed with no output. shellcheck herdr/scripts/herdr-status-report.sh herdr/tests/herdr-cli-update-test.sh passed with no output. git diff --check passed with no output. bash herdr/tests/herdr-cli-update-test.sh ended with "Herdr CLI cache snapshot tests passed" after exercising no-count percent output and count-present compact output.
<!-- SECTION:NOTES:END -->
