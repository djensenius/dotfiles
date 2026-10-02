---
id: TASK-11
title: Fix Herdr image rendering over remote Kitty sessions
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-02 02:01'
updated_date: '2026-10-02 02:01'
labels: []
dependencies: []
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Remote Herdr panes are not displaying inline images even when the client terminal is Kitty. The repo already enables Herdr experimental Kitty graphics locally, so the issue likely involves remote-machine config propagation, terminal capability negotiation, SSH/machine attach behavior, or missing setup documentation/tests for remote Herdr image support.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Remote Herdr configuration and install flow enable the required Kitty graphics/image setting on the remote machine, not only the local checkout.
- [ ] #2 The fix documents any required detach/reattach, terminal, SSH, or Herdr machine steps needed for images to render remotely in Kitty-compatible clients.
- [ ] #3 A validation path is added or documented that can distinguish Herdr config problems from terminal capability or remote transport limitations.
- [ ] #4 Relevant Herdr config/script checks are run and reported.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect current Herdr config/install/docs and installed Herdr CLI support for Kitty graphics, including remote-machine behavior. 2. Identify why remote machines may miss image support despite local kitty_graphics=true. 3. Update repo config/install/docs/tests so remote Herdr sessions get the setting and users have a validation path. 4. Run Herdr/config validations and record evidence.
<!-- SECTION:PLAN:END -->
