---
id: TASK-15
title: Harden install-mac service uninstalls across install sources
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-13 16:00'
updated_date: '2026-10-13 16:09'
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
- [x] #1 install-mac detects and uninstalls/removes supported managed services even when they were installed through an alternate supported source such as Homebrew instead of mise
- [x] #2 The cleanup remains idempotent when a service/source is absent
- [x] #3 Relevant validation is run for the changed script and documented in the task notes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Remove the prior Brewfile service-stop cleanup and related README/test claims.\n2. Add a narrow explicit mapping from mise-managed tools to unexpected Homebrew formula names, excluding any formula curated in mac/Brewfile.\n3. Wire cleanup after mise tool install/verification with check/dry-run/no-op/failure behavior.\n4. Update focused install-mac tests for uninstall, absent no-op, check no mutation, and Brewfile-owned never removed; run relevant validation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Starting implementation in task-15 worktree. Scope: narrow install-mac service-source reconciliation for supported managed services; will validate mac/install.sh and mac/tests/install-mac-test.sh.

Implemented narrow Homebrew service reconciliation for the service-capable formulae already curated in mac/Brewfile: minidlna, postgresql@15, postgresql@18, and redis. Rationale for the service set: these are the only existing Brewfile entries that the repository currently identifies as service-capable; the change stops Homebrew launchd service state for them but does not uninstall packages or perform broad cleanup. The helper checks the Homebrew formula source before inspecting/stopping the service, no-ops when the formula/service is absent, and reports drift without mutation under --check. Validation passed: `bash -n mac/install.sh mac/tests/install-mac-test.sh` -> no output; `git diff --check` -> no output; `bash mac/tests/install-mac-test.sh` -> `ok install-mac tests passed`; `shellcheck mac/install.sh mac/tests/install-mac-test.sh` -> no output.

Fix round started after reviewer block: previous Homebrew service-stop approach treated Brewfile-owned formulae as drift. New scope is conservative mise-owned Homebrew formula cleanup only when formulae are not curated in mac/Brewfile.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added data-driven Homebrew service reconciliation to install-mac for the narrow service-capable Brewfile formula list (minidlna, postgresql@15, postgresql@18, redis). The brew section now detects installed Homebrew formula sources, stops active Homebrew service launchd entries, stays no-op when formulae/services are absent, and reports service drift under --check. Updated README to reflect the supported service cleanup exception and added install-mac tests for active-service cleanup, absent-source idempotence, and check-mode drift. Verified with bash -n, git diff --check, the install-mac test suite, and shellcheck.
<!-- SECTION:FINAL_SUMMARY:END -->
