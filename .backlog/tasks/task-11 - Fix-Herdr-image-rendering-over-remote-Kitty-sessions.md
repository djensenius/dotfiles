---
id: TASK-11
title: Fix Herdr image rendering over remote Kitty sessions
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 02:01'
updated_date: '2026-10-02 02:05'
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
- [x] #1 Remote Herdr configuration and install flow enable the required Kitty graphics/image setting on the remote machine, not only the local checkout.
- [x] #2 The fix documents any required detach/reattach, terminal, SSH, or Herdr machine steps needed for images to render remotely in Kitty-compatible clients.
- [x] #3 A validation path is added or documented that can distinguish Herdr config problems from terminal capability or remote transport limitations.
- [x] #4 Relevant Herdr config/script checks are run and reported.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect current Herdr config/install/docs and installed Herdr CLI support for Kitty graphics, including remote-machine behavior. 2. Identify why remote machines may miss image support despite local kitty_graphics=true. 3. Update repo config/install/docs/tests so remote Herdr sessions get the setting and users have a validation path. 4. Run Herdr/config validations and record evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Research: Herdr 0.9.3 config reference says experimental.kitty_graphics is a deprecated compatibility key for terminal.kitty_graphics, and terminal.kitty_graphics controls image rendering. The same reference says remote sessions split responsibility: server config controls Kitty graphics parsing, local client config controls outer-terminal output. Local herdr status showed client 0.9.3 but server 0.9.1 with server.binary_stale=true, which is a concrete local risk for graphics negotiation.

Implemented: moved the repo Herdr config from deprecated [experimental] kitty_graphics=true to explicit [terminal] kitty_graphics=true; added herdr/scripts/herdr-image-doctor.sh to report terminal env, config key state, Herdr client/server versions, stale server status, and remote troubleshooting steps; documented remote two-ended setup and validation in README.md and pi/README.md.

Validation: HERDR_CONFIG_PATH="$PWD/herdr/config.toml" herdr config check -> config: ok; HERDR_CONFIG_PATH="$PWD/herdr/config.toml" herdr/scripts/herdr-image-doctor.sh reported terminal.kitty_graphics true and server.binary_stale true; bash -n herdr/scripts/herdr-image-doctor.sh -> no output; shellcheck herdr/scripts/herdr-image-doctor.sh -> no output; python3 -m pip install --user tomllint then /opt/homebrew/bin/bash -lc 'shopt -s globstar nullglob; for f in **/*.toml; do [ -f "$f" ] && tomllint "$f"; done' -> success; git diff --check -> no output.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed remote Herdr image setup by switching the repo config to the current terminal.kitty_graphics key, adding a linked herdr-image-doctor diagnostic for local/remote checks, and documenting the required two-ended remote setup, restart/reattach, stale-server, and plain-SSH comparison steps. Verified with herdr config check, the diagnostic script, bash syntax, shellcheck, tomllint across TOML files, and git diff --check.
<!-- SECTION:FINAL_SUMMARY:END -->
