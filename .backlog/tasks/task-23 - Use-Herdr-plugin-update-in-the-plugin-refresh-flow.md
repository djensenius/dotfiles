---
id: TASK-23
title: Use Herdr plugin update in the plugin refresh flow
status: In Progress
assignee:
  - '@copilot-worker'
created_date: 2026-10-15 13:54
updated_date: '2026-10-28T18:28:00Z'
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
- [ ] #1 Confirm `herdr plugin update` exists and its argument form via `herdr plugin update --help` before changing the flow.
- [ ] #2 When `herdr plugin update` is available, the Herdr plugin refresh flow uses it instead of reinstalling each outdated plugin from the cache.
- [ ] #3 Older Herdr versions without `herdr plugin update` still have a working fallback or a clear actionable message.
- [ ] #4 Preserve the existing owner/repo plugin-name validation and `</dev/null` safety in the refreshed shell path.
- [ ] #5 Any README/help text touched by the flow no longer describes native plugin updates as reinstall-only.
- [ ] #6 Validation runs `bash herdr/tests/herdr-cli-update-test.sh` and records the exact command output in the task.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Use a single herdr plugin update --help capability probe before processing cached entries; use native update when supported and legacy install only when unsupported, preserving validation, stdin isolation, and accumulated failures. 2. Extend existing mocked CLI tests for native success, native failure without fallback, and legacy behavior, and revise popup/README wording. 3. Run focused Bash syntax, existing ShellCheck, and Herdr tests; record exact evidence, check verified criteria, commit source changes with required trailers, and finalize TASK-23.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Before code changes, verified installed herdr plugin update --help (exit 0): Update GitHub-installed plugins; Usage: herdr plugin update [OPTIONS] [PLUGIN]...; Options: -y, --yes. Only help was invoked; no live plugin install/update or runtime mutation.
<!-- SECTION:NOTES:END -->
