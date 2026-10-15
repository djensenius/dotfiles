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
