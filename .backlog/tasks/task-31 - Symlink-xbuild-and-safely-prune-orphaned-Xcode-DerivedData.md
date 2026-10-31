---
id: TASK-31
title: Symlink xbuild and safely prune orphaned Xcode DerivedData
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-31T18:31:00Z'
updated_date: '2026-10-31T18:32:00Z'
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
- [ ] #1 Re-running the AI tools installer creates or refreshes ~/.local/bin/xbuild as a symlink to the tracked executable, preserving unrelated existing paths and existing backups.
- [ ] #2 xbuild cleanup-derived-data reports eligible candidates without mutation by default and with --dry-run; --delete removes only verified orphaned direct-child DerivedData entries.
- [ ] #3 Candidates have a valid info.plist WorkspacePath identifying a missing workspace and are at least seven days old according to the newest modification in the entry.
- [ ] #4 Existing workspaces, malformed or unrecognized entries, shared caches, recent orphans, unsafe paths and uncertain filesystem states remain untouched.
- [ ] #5 Cleanup holds the same effective xbuild lock through selection and deletion, cannot overlap cooperating builds, and does not invoke a build or simulator cleanup.
- [ ] #6 Documentation explains installation migration, cleanup usage, age and path safety rules, and locking limitations; focused tests cover candidate selection, safe deletion, symlink migration and lock contention.
<!-- AC:END -->
