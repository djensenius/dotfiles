---
id: TASK-30
title: Default Pi to GPT 6.1 Sol
status: In Progress
assignee:
  - '@djensenius'
created_date: '2026-10-27T18:07:00Z'
updated_date: '2026-10-27T18:07:00Z'
labels: []
dependencies: []
ordinal: 27000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The owner requested GPT 6.1 Sol as Pi's default model instead of GPT 5.5.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Shared Pi default uses github-copilot gpt-6.1-sol while agent overrides remain unchanged
- [ ] #2 Installer regression checks and README reflect the new default
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Change only the shared default model and its installer assertion and README description; run the installer regression suite.
<!-- SECTION:PLAN:END -->
