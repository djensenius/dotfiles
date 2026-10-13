---
id: TASK-15
title: Harden install-mac service uninstalls across install sources
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-13 16:00'
updated_date: '2026-10-13 16:02'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect mac/install.sh service/package reconciliation flow and existing mac/tests/install-mac-test.sh harness.
2. Add a narrow, data-driven cleanup helper for supported services that can detect/remove alternate Homebrew installs while remaining no-op when absent.
3. Wire cleanup into the appropriate install-mac section without broad package cleanup.
4. Add focused tests for alternate-source removal and absent-source idempotence, then run the targeted shell validations.
<!-- SECTION:PLAN:END -->
