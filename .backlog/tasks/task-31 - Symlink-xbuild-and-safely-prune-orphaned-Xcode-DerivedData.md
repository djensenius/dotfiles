---
id: TASK-31
title: Symlink xbuild and safely prune orphaned Xcode DerivedData
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-31T18:31:00Z'
updated_date: '2026-10-31T22:11:00Z'
labels: []
dependencies: []
type: enhancement
ordinal: 28000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Copied xbuild installations drift from the tracked wrapper, and abandoned Xcode DerivedData consumes disk space. Provide an explicit, conservative cleanup tool without risking active builds or uncertain data. Owner approved: cleanup-derived-data defaults to dry-run; deletion requires --delete; scan the standard DerivedData root or XBUILD_DERIVED_DATA_ROOT; require seven days since any modification within an entry; preserve ambiguity; preserve conflicting installed commands as unique backups before linking. Never run cleanup automatically during installation or builds.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Re-running the AI tools installer creates or refreshes ~/.local/bin/xbuild as a symlink to the tracked executable, preserving unrelated existing paths and existing backups.
- [x] #2 xbuild cleanup-derived-data reports eligible candidates without mutation by default and with --dry-run; --delete removes only verified orphaned direct-child DerivedData entries.
- [x] #3 Candidates have a valid info.plist WorkspacePath identifying a missing workspace and are at least seven days old according to the newest modification in the entry.
- [x] #4 Existing workspaces, malformed or unrecognized entries, shared caches, recent orphans, unsafe paths and uncertain filesystem states remain untouched.
- [x] #5 Cleanup holds the same effective xbuild lock through selection and deletion, cannot overlap cooperating builds, and does not invoke a build or simulator cleanup.
- [x] #6 Documentation explains installation migration, cleanup usage, age and path safety rules, and locking limitations; focused tests cover candidate selection, safe deletion, symlink migration and lock contention.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Treat parser AttributeError/IndexError from malformed plist XML as per-entry preservation errors without hiding unrelated failures. 2. Add regressions proving malformed entries remain untouched and later valid orphan candidates are still processed. 3. Re-run focused tests and linting, request a fresh Copilot review after pushing, and merge only after review and CI are clear.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Committed installer migration as 75387e7510e6927ff2fc2ed3a2a03a5e56b7035b. Uses existing link_file without changing its backup semantics. Temporary HOME/BIN_DIR fixtures passed: PASS: xbuild symlink install and rerun; PASS: xbuild symlink migration (matching-copy); PASS: xbuild symlink migration (local-file); PASS: xbuild symlink migration (directory); PASS: xbuild symlink migration (wrong-link); PASS: xbuild symlink migration (dangling-link); installer mise runtime tests passed. Additional checks: installer Git version tests passed; PASS: installer bash syntax; PASS: installer shellcheck; PASS: git diff --check. No real user installation or DerivedData paths were modified.

Implementation committed as 858c816931669df411818cefaaa69e72fbceed0d (following symlink migration 75387e7510e6927ff2fc2ed3a2a03a5e56b7035b). cleanup-derived-data defaults to dry-run and only --delete removes entries. The existing native lockf descriptor lock is unchanged and covers selection, recursive mtime inspection, revalidation and removal. Installed symlink chains resolve to the tracked sibling Python helper. Python 3.11+ and symlink-safe descriptor-relative rmtree are required only for explicit cleanup. XML/binary plist parsing, duplicate/malformed metadata rejection, shared-cache exclusions, recursive newest mtime including exact seven-day boundaries, path/identity checks and fail-closed filesystem handling are covered. Ordinary forwarding, workers, environment overrides, simulator behavior and build exit status remain covered by fake-build integration fixtures.

Conservative safety limits are documented: missing immediate workspace parents (including wholly removed checkouts), any links/special files, other filesystems and known external/network volume paths remain untouched. Revalidation and fd-relative deletion do not make a transaction against non-cooperating writers; stop GUI/direct builds and use the same USER/TMPDIR for cooperating callers. No automatic cleanup, scheduling, extra roots/options, real builds, simulator commands, real user installation changes or real DerivedData deletion were performed.

Final full affected tests ran on implementation commit 858c816931669df411818cefaaa69e72fbceed0d, all exit 0:
- python3 -B ai-tools/tests/xbuild-cleanup-derived-data.py: Ran 30 tests in 1.315s; OK. All 30 per-test lines were ... ok, including test_native_build_lock_delays_cleanup_selection and test_native_cleanup_lock_blocks_build_through_deletion using real /usr/bin/lockf, not a lock mock. The six native wrapper tests are macOS-specific; Ubuntu CI runs the portable cases and explicitly reports those skips.
- bash ai-tools/tests/install-runtime.sh: PASS: xbuild symlink install and rerun; PASS: xbuild symlink migration (matching-copy); PASS: xbuild symlink migration (local-file); PASS: xbuild symlink migration (directory); PASS: xbuild symlink migration (wrong-link); PASS: xbuild symlink migration (dangling-link); installer mise runtime tests passed.
- bash ai-tools/tests/install-git-version.sh: installer Git version tests passed.
- bash -n on ai-tools/bin/xbuild, ai-tools/install.sh, ai-tools/tests/install-runtime.sh: PASS: bash syntax (all changed shell files).
- shellcheck on the same files: PASS: shellcheck (all changed shell files, including extensionless xbuild).
- In-memory Python compile checks: PASS: Python syntax: ai-tools/bin/xbuild-cleanup-derived-data.py; PASS: Python syntax: ai-tools/tests/xbuild-cleanup-derived-data.py.
- PASS: relevant README/AGENTS local links; PASS: git diff --check; PASS: staged git diff --check.
- PASS: yamllint . (temporary dependency restore).
- PASS: actionlint (existing native 1.7.12 via mise exec).

Diagnosed earlier failures, not weakened checks: the initial native deletion-gate fixture failed because its wrapper did not preserve rmtree.avoids_symlink_attacks (AttributeError). functools.wraps now preserves the real function metadata and the real remover is still called; both native contention tests pass. The existing yamllint launcher failed with ModuleNotFoundError: No module named yamllint; yamllint was restored into a temporary pip --target directory and run with python3 -m yamllint ., then the directory was removed. The existing actionlint shim failed with No version is set for shim: actionlint; mise exec actionlint@1.7.12 -- actionlint used the already-installed native binary without configuration changes. No timeouts, assertions, exclusions or existing checks were relaxed.

Ready for coordinator local review. Acceptance criteria remain unchecked and status remains In Progress as requested; coordinator owns final acceptance/status. No forwarding installer files were touched, so mac/tests/install-mac-test.sh was not applicable.

Coordinator verification: python3 -B ai-tools/tests/xbuild-cleanup-derived-data.py: Ran 30 tests in 1.296s; OK, including native xbuild lock-contention and forwarding tests. bash ai-tools/tests/install-runtime.sh: all xbuild symlink install/rerun/migration fixtures passed. bash ai-tools/tests/install-git-version.sh: installer Git version tests passed. bash -n and shellcheck passed for changed shell scripts. yamllint . passed using a temporary isolated package target after the preinstalled launcher lacked its module; mise exec actionlint@1.7.12 -- actionlint passed; git diff --check origin/main...HEAD passed. Independent code review: APPROVE, no significant issues.

Copilot review follow-up: reviewer reproduced two malformed XML plist inputs that make plistlib.loads raise AttributeError or IndexError, neither covered by ENTRY_ERRORS, aborting the scan. Added a narrow follow-up to preserve malformed entries and continue candidate processing.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented tracked xbuild symlink installation and an explicit, dry-run-by-default orphaned DerivedData cleanup command guarded by the existing build lock. The helper validates WorkspacePath metadata, recursive age, path and filesystem safety, and revalidates before deletion; active, malformed, shared-cache, recent, and uncertain entries are preserved. Added focused installer, cleanup, and lock tests and documented usage and limitations. All focused tests/lints passed and local code review approved.
<!-- SECTION:FINAL_SUMMARY:END -->
