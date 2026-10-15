---
id: TASK-28
title: Move Herdr idle battery percentage after hearts
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-15 15:18'
updated_date: '2026-10-15 15:19'
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
- [ ] #1 When no update counts render, the Herdr tab-bar battery display shows hearts followed by the percentage
- [ ] #2 When any update count renders, the display remains compact hearts-only before the counts
- [ ] #3 The tab-bar path remains cache-read-only and does not trigger package checks
- [ ] #4 Tests cover no-count hearts-then-percent output and count-present hearts-only output
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Normalize the idle battery string in herdr-status-report.sh so percent-leading battery_hearts output renders as hearts followed by percent while compact/count-present output stays unchanged.
2. Update the Herdr CLI status test fixture and assertions for idle hearts-then-percent and count-present hearts-only behavior.
3. Run bash syntax, shellcheck, git diff whitespace, and the Herdr CLI update test before finalizing TASK-28.
<!-- SECTION:PLAN:END -->
