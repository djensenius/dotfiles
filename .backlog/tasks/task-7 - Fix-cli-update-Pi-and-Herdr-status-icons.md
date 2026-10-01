---
id: TASK-7
title: Fix cli-update Pi and Herdr status icons
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 17:28'
updated_date: '2026-10-01 17:33'
labels: []
dependencies:
  - TASK-4
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The Herdr cli-update/status display uses icons that do not match the tools well: Pi is shown with a Raspberry Pi glyph instead of mathematical Pi, and Herdr uses an icon that renders shrunken/emoji-like in the status line. That width/rendering problem can interfere with the battery heart display when there are no updates.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Pi update/status entries render with a mathematical Pi-style label/icon rather than a Raspberry Pi logo
- [x] #2 Herdr update/status entries use a stable text or Nerd Font glyph that renders at normal status-line width and is not emoji-style
- [x] #3 The no-updates status still leaves the battery hearts display intact and correctly spaced
- [x] #4 Tests or scripted checks cover cli-update/status rendering for Pi, Herdr, and the no-updates/battery-hearts case
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Replace Pi and Herdr manager icons in both herdr-status-report.sh and herdr-cli-update.sh with stable text-width labels (π for Pi, H for Herdr) while leaving other managers unchanged.
2. Extend herdr-cli-update-test.sh with direct sourced render assertions for manager_icon pi/herdr in both scripts plus tab-bar no-update battery-heart spacing.
3. Run the Herdr CLI update test and direct icon/battery checks; run shellcheck if it is available.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented TASK-7 only: Pi icons now render as π in status and cli-update, and Herdr icons render as the stable text label H. Extended herdr/tests/herdr-cli-update-test.sh to assert status manager icons, cli-update manager icons, status tab-bar no-update battery-heart spacing, and Pi/Herdr draw_screen labels.
Validation passed: bash herdr/tests/herdr-cli-update-test.sh; shellcheck herdr/scripts/herdr-status-report.sh herdr/scripts/herdr-cli-update.sh herdr/tests/herdr-cli-update-test.sh; direct render check printed status π/H, cli-update π/H, and <♥♥♡♡♡> for no-updates.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed Pi and Herdr update/status glyphs in herdr-status-report.sh and herdr-cli-update.sh, keeping scope to TASK-7. Verified with the Herdr CLI cache snapshot test, shellcheck, and a direct sourced render check for Pi, Herdr, and no-update battery hearts.
<!-- SECTION:FINAL_SUMMARY:END -->
