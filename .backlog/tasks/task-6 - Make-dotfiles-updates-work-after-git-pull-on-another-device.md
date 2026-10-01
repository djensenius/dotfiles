---
id: TASK-6
title: Make dotfiles updates work after git pull on another device
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 17:26'
updated_date: '2026-10-01 18:31'
labels: []
dependencies:
  - TASK-4
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Dotfiles changes should become usable on another machine after a normal git pull, like the prior symlink-based setup. Some generated, installed, or machine-local configuration may currently require extra manual install steps, which makes cross-device updates brittle.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Document the expected "git pull on another device" workflow and any one-time prerequisites
- [x] #2 Repo-managed dotfiles that should update automatically are linked or installed in a repeatable way without overwriting machine-local secrets
- [x] #3 Pi/Herdr/agent-stack config changes from repo updates are applied by the documented workflow or clearly called out when a package reinstall is required
- [x] #4 Validation covers at least one dry-run or safe check proving the workflow detects/applies the relevant symlinks or install targets
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Document the post-pull refresh workflow in README.md for macOS, Raspberry Pi, Pi/Herdr agent-stack, and Codespaces boundaries. 2. Add or clarify safe check/dry-run commands that reuse existing installers rather than overwriting local secrets. 3. Validate the documented workflow with existing safe installer checks/tests, especially mac install check/dry-run behavior and agent-stack runtime coverage.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Documented the post-pull workflow in README.md: linked repo-managed dotfiles update immediately after git pull when links exist; macOS uses ./install-mac --check as a read-only drift detector and ./install-mac to repair/sync; Raspberry Pi uses git pull && ./install-pi; Pi/Herdr agent-stack changes require ./install-agent-stack, which merges shared config into ~/.pi/agent. Validation: bash mac/tests/install-mac-test.sh -> ok install-mac tests passed; bash pi/agent-stack/tests/install-runtime.sh -> installer mise runtime tests passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added README guidance for the expected cross-device post-pull workflow, including one-time/link prerequisites, safe macOS check/repair commands, Raspberry Pi refresh behavior, and when to rerun the Pi/Herdr agent-stack installer. Verified with mac install tests and Pi agent-stack runtime tests.
<!-- SECTION:FINAL_SUMMARY:END -->
