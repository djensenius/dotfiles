---
id: TASK-33
title: Manage Herdr App font settings and safe config links
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-11-11T01:45:00Z'
updated_date: '2026-11-11T02:28:00Z'
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
- [x] #1 Tracked desktop settings select Monaspace Neon Var and enable font_ligatures while retaining existing zoom, sounds and minimum_contrast preferences; no unsupported font-face, weight, fallback or OpenType keys are added and existing default size is preserved.
- [ ] #2 macOS, Linux, Raspberry Pi and Codespaces setup manage only the desktop settings.json file within a real herdr-app config directory, without changing TUI config, keys, generated files or runtime state.
- [ ] #3 Link replacement preserves existing desktop settings in a backup, is idempotent on rerun, targets the persistent repository path, and honors each installer applicable dry-run, check, force and skip-links behavior without destructive replacement of app-owned state.
- [ ] #4 Focused existing-suite tests cover initial linking, preserved existing settings and app files, reruns, and relevant read-only or skip modes; applicable shell, JSON and workflow checks pass.
- [x] #5 Documentation explains desktop versus TUI settings, file-level ownership and installation, supported Monaspace and ligature behavior, layout precedence and unsupported advanced face or feature mappings.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Track only herdr-app/settings.json with the existing zoom/sounds/contrast values, Monaspace Neon Var and ligatures; leave size/UI font and TUI config unchanged.
2. Add a narrow shared file-link helper, using installer-relative repository sources, HERDR_APP_HOME when set, byte-preserving collision-safe backups, real config directories and safe refusal of directory symlinks. Wire it into macOS/Linux/Pi/Codespaces with existing dry-run/check/skip policies; retain unrelated force behavior and native macOS/Pi backup locations.
3. Extend the existing macOS/Linux harnesses and add a focused Pi/Codespaces/shared regression harness exercising the actual installer paths in temporary homes. Make Codespaces function definitions source-safe for bounded testing, without running bootstrap/software installation, and register the focused suite in existing shell CI.
4. Document desktop/TUI separation, file ownership, installer/backup behavior, layout precedence and v0.1.15 font limits. Run focused suites, shell syntax/ShellCheck, JSON assertions and required YAML/workflow checks; append evidence, commit logical changes with the requested trailers, and finalize TASK-33 with live adoption explicitly pending.

CI registration refinement: invoke the new cross-platform desktop suite from the already-CI-registered macOS test runner, rather than editing workflow YAML. Seed desktop settings links in existing fully-configured macOS fixtures; keep their whole-home snapshots and drift assertions intact.

Review fix round 1 (P2 on HEAD 1e1ff8d28969d3342dd599c5478e478d817bd0df): extend the existing four-installer unsafe-home assertions to cover trailing /. and repeated dot/slash spellings, and run them before changing the helper to prove the gap. Then normalize only trailing slash/current-directory components lexically, without resolving symlinks, retaining absolute root and ordinary override handling. Verify refusal and unchanged referent/backups through all four actual installer paths, plus safe read-only root spelling coverage; run the focused suite, affected bash syntax/managed ShellCheck and diff checks, commit normally, and record final evidence before Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Research confirmed no current desktop integration; macOS uses manifest plus special link rules and read-only counters, Linux leaves existing targets unless forced, Pi force deletes unrelated targets, and Codespaces executes bootstrap on source today. Implementation will preserve those unrelated semantics. The coordinator verified installed v0.1.15 font support and atomic-write symlink preservation; Herdr App source, existing Monaspace casks and live ~/.config are outside this worker change. Unsafe desktop directory links/non-directories will be left intact with an actionable error instead of migrating app-owned files.

Implemented the settings file and shared file-only link path for all four installers. The isolated suite passed all 16 named platform/scenario cases. Diagnosed initial test failure as macOS /var versus /private/var fixture-path spelling; canonicalized the fixture root while retaining the exact source-link assertion. Removed callback-only adapters and renamed the test repository variable to resolve ShellCheck static-analysis findings without ignores. Shell syntax (8 files), managed ShellCheck (8 files), exact JSON assertion and yamllint passed. Existing macOS suite exposed a newly incomplete fixture: its no-adopt whole-home snapshot now legitimately gains the new desktop link. Will seed the newly required configured state rather than exclude it. Default jactionlint reported six existing workflow policy findings (concurrency, timeout, permissions, two unpinned actions, checkout credentials), not new-step errors; retain existing workflow and register tests through its existing macOS runner. Live settings/font adoption remains solely the coordinator responsibility.

Final objective evidence on committed source/docs 304542ef4c02a943069e9c6689780537b76c5974 (implementation 22b210eac9b828a9d0d1b6e3db3c087810f37ba9):
- AC1: mise exec -- jq -e exact-object assertion returned true; only zoom=1.0, sounds.enabled=true, minimum_contrast=1.0, font=Monaspace Neon Var and font_ligatures=true are tracked. font_size/ui_font and unsupported advanced keys are absent.
- AC2/3: production macOS/Linux/Pi installer scripts and Codespaces link_files were exercised in disposable fixture repos/homes, from a different cwd. All 16 named platform/scenario cases passed. Tests assert real directory/file-only ownership, unchanged keys/generated instructions/types/layouts/mods/binary runtime sentinels, original bytes saved (including relative file links), collision-safe backups under a frozen clock, correct/dangling links and existing directory replacement, idempotent reruns, custom HERDR_APP_HOME with spaces, and safe refusal of directory symlinks (including trailing slash) and non-directory homes. Linux no-force skip, Mac clean/drift check exits 0/2, Mac/Linux/Pi dry-run, link skipping, and Pi --force preservation are covered; Pi unrelated force deletion semantics are separately asserted unchanged.
- AC4 final runner output: Herdr App settings tests: 16 passed, 0 failed; ok install-mac tests passed; install-linux tests passed; Pi herdr-fish cleanup: exit 0 (3 cases). bash -n: Shell syntax: 8 files passed. mise exec -- shellcheck: ShellCheck: 8 files passed. jq exact assertion: true. yamllint .: passed. Committed diff whitespace: passed. The desktop suite runs from the existing CI-registered macOS harness; no workflow change is needed.
- Diagnosed and fixed the existing Mac configured-home fixture by seeding its new correct desktop link before whole-home snapshots and clean-check assertions; no assertion, timeout or test was weakened. Default jactionlint was also run against the original base workflow via git show 7d6ddea065254a8e852acbf78b64e9bc10c341af and reproduced the same six pre-existing policy findings/exit 1 (concurrency, timeout, permissions, checkout pin, checkout credentials, shellcheck action pin). Workflow YAML is byte-unchanged in this task; no policies were suppressed or unrelated fixes made.
- AC5: README and Pi README document desktop/TUI separation, supported font/ligature settings and 14px default, unset UI font, unsupported face/weight/fallback/line-height/OpenType mappings, layout override precedence (main honors defaults), file ownership, installer modes/backups, and safe settings-only adoption from a persistent clone. git diff against the supplied base confirms herdr/config.toml, mac/Brewfile and workflow are unchanged.
Both manual implementation/documentation commits include the requested Co-authored-by and Copilot-Session trailers. No push, PR, merge, app source change, package bootstrap or live config write was performed by this worker. Permanent live adoption remains pending coordinator review and arrival in the stable checkout; coordinator may independently enable the live font first. App-side writes preserve the eventual symlink and may dirty the tracked settings target.

Reopened for the persisted local reviewer REQUEST CHANGES report at /Users/david/.copilot/session-state/90f940df-55c2-48ce-bfc4-2d5274852701/files/herdr-fonts-review-1.txt. One actionable P2: HERDR_APP_HOME ending in /., unlike a trailing slash alone, hides a directory symlink from the leaf -L guard. Scope is strictly that path-spelling defect and regression tests; installer policies, YAML/jactionlint policies, font settings, live config and Herdr App source remain unchanged. AC2/3/4 temporarily unchecked until the new evidence is collected.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented desktop Monaspace Neon Var and enabled ligatures using only supported existing settings, preserving personal preferences and the installed default size. All four installers now manage only settings.json in a real desktop config home with byte-preserving backups, safe modes, HERDR_APP_HOME support, and unchanged unrelated force behavior. Added 16 cross-platform production-path regression cases through existing CI plus concise ownership/font-limit/adoption documentation. Final affected installer suites, shell syntax/ShellCheck, exact JSON, YAML and whitespace checks passed. Six stricter jactionlint policy findings are confirmed pre-existing on the unchanged base workflow and left out of scope. Implementation: 22b210eac9b828a9d0d1b6e3db3c087810f37ba9; docs: 304542ef4c02a943069e9c6689780537b76c5974. Stable-checkout/live symlink adoption and reviewer/PR remain the coordinator responsibility; worker did not touch live config or Herdr App source.
<!-- SECTION:FINAL_SUMMARY:END -->
