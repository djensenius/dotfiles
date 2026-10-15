---
id: TASK-27
title: Show battery percent when Herdr status has no updates
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-15 14:47'
updated_date: '2026-10-15 14:49'
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
- [ ] #1 When any software-update count is rendered, the Herdr tab-bar battery display remains the compact hearts-only form
- [ ] #2 When no software-update counts are rendered, the battery display includes percentage next to the hearts
- [ ] #3 The status helper remains fast and uses cached package counts rather than triggering package checks from the tab-bar path
- [ ] #4 Tests or scripted checks cover both update-count-present and no-update-count rendering cases
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the Herdr tab-bar renderer and tests to keep the change limited to battery argument selection based on cached update-count output.
2. Update the status helper so render_tab_bar reads cached manager counts first, uses compact battery hearts when any count will be shown, and uses battery_hearts --threshold 1 when no counts will be shown.
3. Update the Herdr CLI/tab-bar test stub to assert both no-update percent output and update-count compact output without invoking package checks.
4. Run the targeted Herdr test and shell syntax checks, then record evidence, check acceptance criteria, and finish the task.
<!-- SECTION:PLAN:END -->
