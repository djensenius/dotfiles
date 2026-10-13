---
id: TASK-15
title: Harden install-mac service uninstalls across install sources
status: To Do
assignee: []
created_date: '2026-10-13 16:00'
labels: []
dependencies: []
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The macOS installer currently assumes services were installed through the expected package manager, but local machines can have the same service installed through another source such as Homebrew instead of mise. Re-running the script should clean up conflicting service installs regardless of the likely original source.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 install-mac detects and uninstalls/removes supported managed services even when they were installed through an alternate supported source such as Homebrew instead of mise
- [ ] #2 The cleanup remains idempotent when a service/source is absent
- [ ] #3 Relevant validation is run for the changed script and documented in the task notes
<!-- AC:END -->
