---
id: TASK-15
title: Harden install-mac service uninstalls across install sources
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-13 16:00'
updated_date: '2026-10-13 16:15'
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
1. Revert the prior Brewfile Homebrew service-stop cleanup and README/test claims.
2. Add a narrow explicit source-reconciliation list that maps current mise/config.toml tools to matching Homebrew formula names, using Brewfile membership only as a skip guard.
3. Run the cleanup from the mise section after install/verification: normal mode uninstalls unexpected formulae, --check reports drift, --dry-run reports would-uninstall, absent formulae and unavailable brew are no-ops.
4. Update focused install-mac tests for unexpected formula uninstall, absent no-op, dry-run, --check no mutation, and Brewfile-owned formula preservation; run shell validation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Starting implementation in task-15 worktree. Scope: narrow install-mac service-source reconciliation for supported managed services; will validate mac/install.sh and mac/tests/install-mac-test.sh.

Implemented narrow Homebrew service reconciliation for the service-capable formulae already curated in mac/Brewfile: minidlna, postgresql@15, postgresql@18, and redis. Rationale for the service set: these are the only existing Brewfile entries that the repository currently identifies as service-capable; the change stops Homebrew launchd service state for them but does not uninstall packages or perform broad cleanup. The helper checks the Homebrew formula source before inspecting/stopping the service, no-ops when the formula/service is absent, and reports drift without mutation under --check. Validation passed: `bash -n mac/install.sh mac/tests/install-mac-test.sh` -> no output; `git diff --check` -> no output; `bash mac/tests/install-mac-test.sh` -> `ok install-mac tests passed`; `shellcheck mac/install.sh mac/tests/install-mac-test.sh` -> no output.

Fix round started after reviewer block: previous Homebrew service-stop approach treated Brewfile-owned formulae as drift. New scope is conservative mise-owned Homebrew formula cleanup only when formulae are not curated in mac/Brewfile.

Fix round correction implemented. Removed the MANAGED_HOMEBREW_SERVICE_FORMULAE/Homebrew services stop behavior entirely; install_brew now only reconciles the curated Brewfiles. Added a manual MISE_OWNED_HOMEBREW_FORMULAE mapping (mise tool -> Homebrew formula) and cleanup in the mise section. The cleanup first confirms the mise tool is configured, then skips any formula curated in mac/Brewfile/mac/Brewfile.apps, no-ops when brew is unavailable or the formula is absent, reports drift under --check, prints would-uninstall under --dry-run, uninstalls in normal mode, and fails explicitly if brew uninstall fails.

Reviewer blockers addressed: (1) Brewfile-owned Homebrew services/formulae are not alternate-source drift; Brewfile formulae are skipped and no service inspection remains. (2) install-mac no longer stops user-started PostgreSQL, Redis, minidlna, or any other Homebrew service. (3) --check reports drift only for explicit mise-owned Homebrew formula installs that are not in the Brewfile, not for intended Brewfile services. (4) README now documents only the narrow mise-owned formula uninstall exception and explicitly says Brewfile formulae are kept and install-mac does not stop their Homebrew services.

Validation passed after the code commit: bash -n mac/install.sh mac/tests/install-mac-test.sh -> status 0; git diff --check -> status 0; bash mac/tests/install-mac-test.sh -> ok install-mac tests passed, status 0; shellcheck mac/install.sh mac/tests/install-mac-test.sh -> status 0.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced the blocked Homebrew service-stop implementation with conservative mise-owned Homebrew formula cleanup. The corrected install-mac flow does not inspect or stop Brewfile services; after the mise section verifies or installs tools, it uninstalls only explicit mapped formulae for tools still present in mise/config.toml and only when those formulae are not curated in the Brewfiles. Check mode reports that formula drift without mutation, dry-run prints would-uninstall, absent formulae/brew are no-ops, and uninstall failures are explicit failures. README and install-mac tests were updated to cover the corrected policy. Verified with bash -n, git diff --check, bash mac/tests/install-mac-test.sh, and shellcheck.
<!-- SECTION:FINAL_SUMMARY:END -->
