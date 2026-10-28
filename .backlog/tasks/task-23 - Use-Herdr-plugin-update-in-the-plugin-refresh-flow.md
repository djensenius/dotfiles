---
id: TASK-23
title: Use Herdr plugin update in the plugin refresh flow
status: Done
assignee:
  - '@copilot-worker'
created_date: 2026-10-15 13:54
updated_date: '2026-10-28T18:29:00Z'
labels: []
dependencies: []
modified_files:
  - herdr/scripts/herdr-cli-update.sh
  - herdr/tests/herdr-cli-update-test.sh
  - README.md
type: task
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-22 found that the repo Herdr plugin refresher currently reinstalls each outdated plugin listed in the cache with `herdr plugin install <plugin> --yes`, while current Herdr exposes `herdr plugin update`. Refreshing outdated cached plugins via the native update command should reduce needless reinstall behavior without dropping compatibility for older Herdr binaries.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Confirm `herdr plugin update` exists and its argument form via `herdr plugin update --help` before changing the flow.
- [x] #2 When `herdr plugin update` is available, the Herdr plugin refresh flow uses it instead of reinstalling each outdated plugin from the cache.
- [x] #3 Older Herdr versions without `herdr plugin update` still have a working fallback or a clear actionable message.
- [x] #4 Preserve the existing owner/repo plugin-name validation and `</dev/null` safety in the refreshed shell path.
- [x] #5 Any README/help text touched by the flow no longer describes native plugin updates as reinstall-only.
- [x] #6 Validation runs `bash herdr/tests/herdr-cli-update-test.sh` and records the exact command output in the task.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Use a single herdr plugin update --help capability probe before processing cached entries; use native update when supported and legacy install only when unsupported, preserving validation, stdin isolation, and accumulated failures. 2. Extend existing mocked CLI tests for native success, native failure without fallback, and legacy behavior, and revise popup/README wording. 3. Run focused Bash syntax, existing ShellCheck, and Herdr tests; record exact evidence, check verified criteria, commit source changes with required trailers, and finalize TASK-23.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Before code changes, verified installed herdr plugin update --help (exit 0): Update GitHub-installed plugins; Usage: herdr plugin update [OPTIONS] [PLUGIN]...; Options: -y, --yes. Only help was invoked; no live plugin install/update or runtime mutation.

Final source commit: 376f1a24a693b00291853248136183b626a79d7e. Native and legacy success tests assert the exact help probe and per-plugin argv. Failure tests assert exact call logs (no install after native failures), continued processing after errors, rejected invalid names, and stdin-consuming mock safety in both paths. README and popup describe native update with legacy install compatibility.

Validation after source commit (all exit 0):
Command: bash -n herdr/scripts/herdr-cli-update.sh herdr/tests/herdr-cli-update-test.sh
Output: (none); wrapper result: Bash syntax checks passed
Command: shellcheck herdr/scripts/herdr-cli-update.sh herdr/tests/herdr-cli-update-test.sh
Output: (none); wrapper result: ShellCheck passed
Command: git --no-pager diff --check
Output: (none); wrapper result: git diff --check passed
Command: bash herdr/tests/herdr-cli-update-test.sh
Exact combined stdout/stderr:
[1mUpdating owner/old-plugin...[0m
[1mUpdating owner/new-plugin...[0m
Herdr plugin update success tests passed
[1mReinstalling owner/old-plugin...[0m
[1mReinstalling owner/new-plugin...[0m
Herdr plugin install success tests passed
[1mUpdating owner/old-plugin...[0m
cli-update: skipping invalid Herdr plugin name: bad;name
cli-update: skipping invalid Herdr plugin name: ../escape
cli-update: skipping invalid Herdr plugin name: owner/..
cli-update: skipping invalid Herdr plugin name: -flag/repo
[1mUpdating owner/fail-plugin...[0m
[1mUpdating owner/new-plugin...[0m
Herdr plugin update failure, validation and stdin safety tests passed
[1mReinstalling owner/old-plugin...[0m
cli-update: skipping invalid Herdr plugin name: bad;name
cli-update: skipping invalid Herdr plugin name: ../escape
cli-update: skipping invalid Herdr plugin name: owner/..
cli-update: skipping invalid Herdr plugin name: -flag/repo
[1mReinstalling owner/fail-plugin...[0m
[1mReinstalling owner/new-plugin...[0m
Herdr plugin install failure, validation and stdin safety tests passed
Herdr CLI cache snapshot tests passed

No live plugin install/update was invoked. Only the installed CLI help contract was verified; update execution was tested using isolated mocks.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Prefer native Herdr plugin update using an explicit help capability probe, falling back to install only for unsupported versions. Preserve cached owner/repo validation, stdin isolation, and accumulated failures. Updated README/popup and expanded native/legacy success and failure tests. Focused Bash syntax, ShellCheck, whitespace, and complete Herdr CLI test suite pass; exact output is recorded above. No live plugins were modified; real native update execution remains intentionally untested.
<!-- SECTION:FINAL_SUMMARY:END -->
