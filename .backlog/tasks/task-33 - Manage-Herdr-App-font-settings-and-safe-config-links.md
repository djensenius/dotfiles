---
id: TASK-33
title: Manage Herdr App font settings and safe config links
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-11-11T01:45:00Z'
updated_date: '2026-11-11T01:57:00Z'
labels:
  - herdr
  - desktop
dependencies: []
references:
  - https://github.com/herdrdev/herdr-app/blob/master/defaults/AGENTS.md
type: enhancement
ordinal: 29000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The desktop Herdr App has a separate settings home from Herdr TUI and currently is not managed by dotfiles, so the existing Monaspace terminal preferences and enabled programming ligatures do not carry over. The owner confirmed using only the app existing supported settings, not modifying the app source, and requested integration across all applicable installers. The live Mac settings must be preserved before adoption; generated app files, keybinds and runtime state must remain unmanaged.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Tracked desktop settings select Monaspace Neon Var and enable font_ligatures while retaining existing zoom, sounds and minimum_contrast preferences; no unsupported font-face, weight, fallback or OpenType keys are added and existing default size is preserved.
- [ ] #2 macOS, Linux, Raspberry Pi and Codespaces setup manage only the desktop settings.json file within a real herdr-app config directory, without changing TUI config, keys, generated files or runtime state.
- [ ] #3 Link replacement preserves existing desktop settings in a backup, is idempotent on rerun, targets the persistent repository path, and honors each installer applicable dry-run, check, force and skip-links behavior without destructive replacement of app-owned state.
- [ ] #4 Focused existing-suite tests cover initial linking, preserved existing settings and app files, reruns, and relevant read-only or skip modes; applicable shell, JSON and workflow checks pass.
- [ ] #5 Documentation explains desktop versus TUI settings, file-level ownership and installation, supported Monaspace and ligature behavior, layout precedence and unsupported advanced face or feature mappings.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Track only herdr-app/settings.json with the existing zoom/sounds/contrast values, Monaspace Neon Var and ligatures; leave size/UI font and TUI config unchanged.
2. Add a narrow shared file-link helper, using installer-relative repository sources, HERDR_APP_HOME when set, byte-preserving collision-safe backups, real config directories and safe refusal of directory symlinks. Wire it into macOS/Linux/Pi/Codespaces with existing dry-run/check/skip policies; retain unrelated force behavior and native macOS/Pi backup locations.
3. Extend the existing macOS/Linux harnesses and add a focused Pi/Codespaces/shared regression harness exercising the actual installer paths in temporary homes. Make Codespaces function definitions source-safe for bounded testing, without running bootstrap/software installation, and register the focused suite in existing shell CI.
4. Document desktop/TUI separation, file ownership, installer/backup behavior, layout precedence and v0.1.15 font limits. Run focused suites, shell syntax/ShellCheck, JSON assertions and required YAML/workflow checks; append evidence, commit logical changes with the requested trailers, and finalize TASK-33 with live adoption explicitly pending.

CI registration refinement: invoke the new cross-platform desktop suite from the already-CI-registered macOS test runner, rather than editing workflow YAML. Seed desktop settings links in existing fully-configured macOS fixtures; keep their whole-home snapshots and drift assertions intact.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Research confirmed no current desktop integration; macOS uses manifest plus special link rules and read-only counters, Linux leaves existing targets unless forced, Pi force deletes unrelated targets, and Codespaces executes bootstrap on source today. Implementation will preserve those unrelated semantics. The coordinator verified installed v0.1.15 font support and atomic-write symlink preservation; Herdr App source, existing Monaspace casks and live ~/.config are outside this worker change. Unsafe desktop directory links/non-directories will be left intact with an actionable error instead of migrating app-owned files.

Implemented the settings file and shared file-only link path for all four installers. The isolated suite passed all 16 named platform/scenario cases. Diagnosed initial test failure as macOS /var versus /private/var fixture-path spelling; canonicalized the fixture root while retaining the exact source-link assertion. Removed callback-only adapters and renamed the test repository variable to resolve ShellCheck static-analysis findings without ignores. Shell syntax (8 files), managed ShellCheck (8 files), exact JSON assertion and yamllint passed. Existing macOS suite exposed a newly incomplete fixture: its no-adopt whole-home snapshot now legitimately gains the new desktop link. Will seed the newly required configured state rather than exclude it. Default jactionlint reported six existing workflow policy findings (concurrency, timeout, permissions, two unpinned actions, checkout credentials), not new-step errors; retain existing workflow and register tests through its existing macOS runner. Live settings/font adoption remains solely the coordinator responsibility.
<!-- SECTION:NOTES:END -->
