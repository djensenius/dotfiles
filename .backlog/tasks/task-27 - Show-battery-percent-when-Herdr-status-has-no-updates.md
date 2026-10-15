---
id: TASK-27
title: Show battery percent when Herdr status has no updates
status: To Do
assignee: []
created_date: '2026-10-15 14:47'
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
