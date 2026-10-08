---
id: TASK-13
title: Switch Pi memory extension from pi-memctx to pi-memory
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-08 13:47'
updated_date: '2026-10-08 13:55'
labels: []
dependencies: []
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The installed pi-memctx extension keeps triggering Pi extension loader warnings because its published package declares @sinclair/typebox under dependencies instead of peerDependencies. The owner asked to switch the repo-managed agent stack to pi-memory, which currently has much higher npm usage and avoids the recurring local pi-memctx manifest workaround.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Repo-managed Pi package configuration installs npm:pi-memory instead of npm:pi-memctx
- [x] #2 README or relevant agent-stack documentation names pi-memory instead of pi-memctx where the default extension set is documented
- [x] #3 Agent-stack tests or fixtures that assert the package list are updated consistently
- [x] #4 The relevant validation checks pass and their output is recorded in the task notes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Reopen TASK-13 and record the reviewer blocker and revised plan before source edits.
2. Add npm:pi-memctx, including @version suffixes, to install.sh stale package removal while preserving pi-memory as the managed package.
3. Add an install-runtime migration test for existing npm:pi-memctx removal and pi-memory managed installation.
4. Update README upgrade/footer documentation and catppuccin footer fixture to remove stale memctx footer exclusion text.
5. Run install-runtime.sh and targeted grep consistency checks, then record evidence and finalize TASK-13 with residual mocked-install risk noted.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Validation run after replacing pi-memctx with pi-memory:
- `bash pi/agent-stack/tests/install-runtime.sh` -> `installer mise runtime tests passed`
- `grep -nH 'pi-memctx' pi/agent-stack/packages.txt README.md pi/agent-stack/tests/install-runtime.sh || true` -> no matches in touched package/docs/test files
- `grep -nH 'pi-memory' pi/agent-stack/packages.txt README.md pi/agent-stack/tests/install-runtime.sh` -> `pi/agent-stack/packages.txt:7:npm:pi-memory`; `README.md:526:\`npm:pi-web-access\`, \`npm:pi-browser-harness\`, \`npm:pi-memory\`, and`; `pi/agent-stack/tests/install-runtime.sh:16:  "npm:pi-memory"`

Reviewer blocker on commit 6ea5d7328b7ed2184fffc9599a943cd09ddc4512: installer did not remove superseded npm:pi-memctx on upgrade, and README/footer fixture still documented stale memctx footer exclusion even though pi-memory does not publish that status key.

Fix-round validation for reviewer blocker on commit 6ea5d7328b7ed2184fffc9599a943cd09ddc4512:
- Updated `pi/agent-stack/install.sh` so stale package detection includes `^$MEMCTX_SOURCE(@|$)` for superseded `npm:pi-memctx` installs, including version-suffixed sources.
- Added `pi/agent-stack/tests/install-runtime.sh` scenario `run_memctx_upgrade_migration`, which asserts `exec:pi remove:npm:pi-memctx` exactly once, `exec:pi install:npm:pi-memory` exactly once through the normal managed package flow, and subagents still install/update.
- Updated README upgrade/footer documentation and `pi/agent-stack/catppuccin-footer.json` so footer config no longer excludes or documents stale `memctx` status.
- `bash pi/agent-stack/tests/install-runtime.sh` -> `installer mise runtime tests passed`.
- `grep -nH -E 'pi-memctx|pi-memory' README.md pi/agent-stack/packages.txt pi/agent-stack/install.sh pi/agent-stack/tests/install-runtime.sh pi/agent-stack/catppuccin-footer.json || true` key lines: `README.md:526` lists `npm:pi-memory`; `README.md:528-529` documents removal of `npm:pi-memctx` after installing `npm:pi-memory`; `pi/agent-stack/packages.txt:7:npm:pi-memory`; `pi/agent-stack/install.sh:32:MEMCTX_SOURCE="npm:pi-memctx"`; `pi/agent-stack/tests/install-runtime.sh:10-11` define `MEMCTX_SOURCE`/`PI_MEMORY_SOURCE`.
- `grep -nH 'MEMCTX_SOURCE\|PI_MEMORY_SOURCE\|stale_sources\|exec:pi remove' pi/agent-stack/install.sh pi/agent-stack/tests/install-runtime.sh | sed -n '1,80p'` key lines: `pi/agent-stack/install.sh:418` includes `^$MEMCTX_SOURCE(@|$)` in `stale_sources`; `pi/agent-stack/tests/install-runtime.sh:1025-1026` assert remove of memctx and install of pi-memory.
- `grep -nH '"memctx"' pi/agent-stack/catppuccin-footer.json || true` -> no output.
Residual risk: validation uses the mocked installer/runtime harness, not a live Pi upgrade with real npm packages.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fix round for TASK-13 removed the reviewer blocker by retiring superseded npm:pi-memctx during agent-stack upgrades (including version-suffixed sources), adding a mocked migration test that verifies one pi remove for memctx and normal managed npm:pi-memory installation, and removing stale memctx footer documentation/configuration. Verified with bash pi/agent-stack/tests/install-runtime.sh plus targeted grep consistency checks; residual risk is limited to not exercising a live Pi/npm upgrade.
<!-- SECTION:FINAL_SUMMARY:END -->
