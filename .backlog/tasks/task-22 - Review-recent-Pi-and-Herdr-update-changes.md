---
id: TASK-22
title: Review recent Pi and Herdr update changes
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-15 13:50'
updated_date: '2026-10-15 13:53'
labels: []
dependencies: []
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Recent Pi and Herdr releases changed update flows and integration behavior. Herdr now exposes commands such as `herdr update` and `herdr plugin update`, while Pi 1.2.0 adds schema and extension-event changes. Review the current local versions, release notes, and dotfiles scripts/docs to identify small follow-up changes worth implementing without mixing them into TASK-21.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Review current local Pi and Herdr versions/update status and note any server/client mismatch or package-manager caveat
- [ ] #2 Identify relevant recent Pi changes that affect this repo's settings, extensions, docs, or installer
- [ ] #3 Identify relevant recent Herdr changes that affect this repo's config, plugin updater, docs, or installer
- [ ] #4 Create follow-up Backlog tasks for implementation candidates or explicitly record that no repo changes are needed
<!-- AC:END -->
