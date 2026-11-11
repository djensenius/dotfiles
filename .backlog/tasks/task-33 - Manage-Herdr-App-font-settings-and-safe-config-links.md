---
id: TASK-33
title: Manage Herdr App font settings and safe config links
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-11-11T01:45:00Z'
updated_date: '2026-11-11T03:21:00Z'
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
- [x] #2 macOS, Linux, Raspberry Pi and Codespaces setup manage only the desktop settings.json file within a real herdr-app config directory, without changing TUI config, keys, generated files or runtime state.
- [x] #3 Link replacement preserves existing desktop settings in a backup, is idempotent on rerun, targets the persistent repository path, and honors each installer applicable dry-run, check, force and skip-links behavior without destructive replacement of app-owned state.
- [x] #4 Focused existing-suite tests cover initial linking, preserved existing settings and app files, reruns, and relevant read-only or skip modes; applicable shell, JSON and workflow checks pass.
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

CI/Copilot round 1 on PR #506, reviewed HEAD f402f6c4835853a8db5f0fa8220f5411134e73f1: reproduce standalone ShellCheck 0.11.0 and add parent-traversal/XDG actual-installer regressions before helper changes. Make the Codespaces timing callbacks statically reachable without ignores or check changes. Select the app home using nonempty HERDR_APP_HOME, then nonempty XDG_CONFIG_HOME/herdr-app, then HOME/.config/herdr-app; isolate ambient overrides in temporary-home test harnesses. Reject every parent-directory component before filesystem changes, retaining safe lexical suffix/root behavior. Update only related default/override documentation and reporting. Run focused regressions, individually lint all PR-touched shell files as CI does, syntax checks and any directly affected harness checks; make one normal fix commit with required trailers, then finalize with exact evidence. No workflow/TOML/Brewfile, app source, live config, push or unrelated policy changes.
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

Review fix round 1 evidence (P2):
- Added the new regression before changing the helper. git diff --exit-code against reviewed HEAD 1e1ff8d28969d3342dd599c5478e478d817bd0df confirmed the helper was unchanged; the focused suite exited 1 with: not ok mac accepted a symlinked desktop config directory: /.config/herdr-app/.
- Committed the bounded helper/test fix as f3f22f2383013ae629c3b79eb20c64c852d4865f, including the requested Co-authored-by and Copilot-Session trailers. Trailing slash/current-directory components are normalized lexically; no symlinks are resolved away.
- Final focused suite on that commit printed each of the 16 existing platform/scenario passes plus ok root_home_spellings and Herdr App settings tests: 17 passed, 0 failed. All four actual installer paths reject six linked-home spellings (plain, trailing slash, /., /./, /././/, and //.///./); assertions preserve the directory link target, personal settings bytes, all referent state and the backup inventory. Real override paths with spaces and trailing dot/slash variants still succeed unchanged. Root /, //, /., /./ and /./.// are tested read-only in an isolated shell with a false/no-write command runner.
- Final validation output: Shell syntax: 8 files passed; ShellCheck: 8 files passed; Review-round diff whitespace: passed; Unrelated installers, settings, TUI, Brewfile and workflows: unchanged. An initial two-file lint invocation lacked the Codespaces source context; the full eight-file source set resolved the callback-only diagnostics. The new in-process root probe also exposed a HOME subshell-analysis diagnostic, so the probe was isolated in its own shell with an explicit scratch HOME and no-write runner. No lint ignores, assertion removals or timeout changes were added.
- Only the shared helper, focused test and CLI-managed TASK-33 metadata changed in this round. No YAML, JSON, installer-policy, app-source or live-config changes; no jactionlint policy work, push, PR or merge. Broader suites were not rerun because the focused suite exercises every affected production installer path. Same-reviewer re-review and stable/live adoption remain coordinator follow-ups.

Reopened from local approval because actual PR #506 CI run 42949033670 (ShellCheck 0.11.0, one file per invocation) fails SC2329 for test timing callbacks at lines 90/91; prior combined eight-file lint was not CI-faithful. Copilot review 5853122864 comments 4533409495 and 4533409539 identify missing XDG_CONFIG_HOME fallback and a parent-traversal symlink-home bypass via linked_home/layouts/... followed by a parent component. Full evidence was read from /Users/david/.copilot/session-state/90f940df-55c2-48ce-bfc4-2d5274852701/files/herdr-fonts-ci-copilot-round-1.txt. Coordinator independently verified the app home precedence on every OS. AC2/3/4/5 temporarily unchecked for this bounded fix round.

CI/Copilot regression evidence on unchanged production helper f402f6c: individual managed ShellCheck 0.11.0 exited 1 with SC2329 at focused-test lines 90/91. Added parent-traversal tests first; focused suite exited 1 after the first three Mac cases with: not ok mac accepted a symlinked desktop config directory: /.config/herdr-app/layouts/... (the final component was literal ..). Added XDG matrix next; unchanged production code exited 1 with: not ok mac selected the wrong config home: xdg-only. Both red runs verified production helper had no diff from f402f6c before running. Fix now follows verified HERDR_APP_HOME > XDG_CONFIG_HOME/herdr-app > HOME/.config/herdr-app nonempty precedence; rejects whole .. path components lexically before any target writes; retains suffix/root handling. All four actual installer paths now assert six empty/unset/precedence combinations, byte-preserving backups and untouched losing config homes; unsafe tests cover layouts/.., layouts/../. and layouts/../mods/.. with unchanged referent, directory link and backup list. Mac reporting now names the selected XDG-aware target. Temporary-home Mac/Linux/Pi/focused harnesses clear ambient config-home overrides. A first callback-export attempt deterministically still failed standalone SC2329; minimal stdin probes showed the lint checks subshell-local definitions even through a setup function. Final structure loads source-safe Codespaces definitions once with disposable HOME and declares the timing callbacks at harness top level, preserving actual link_files execution without ignores or check changes. Current focused output: Herdr App settings tests: 21 passed, 0 failed. CI-faithful one-file-per-invocation ShellCheck 0.11.0 and bash -n passed all nine PR-touched shell files; git diff --check PASS. No YAML/TOML/Brewfile changes. Remaining before finalization: normal fix commit, final directly affected harness checks including ambient-override isolation, and objective task evidence.

Final CI/Copilot round evidence on normal implementation commit a0baf1d89afa9b72f50e3e2b88738c2405d3a6d0 (required Co-authored-by and Copilot-Session trailers present):
- Exact pre-fix parent-traversal failure: not ok mac accepted a symlinked desktop config directory: /.config/herdr-app/layouts/..
- Exact pre-fix XDG failure: not ok mac selected the wrong config home: xdg-only
- Initial individual ShellCheck 0.11.0 exited 1 with SC2329 at focused-test lines 90/91; the intermediate export-only attempt also failed deterministically. Final callback setup fixes declaration lifetime rather than suppressing lint. Nine individual file invocations now pass: herdr-app/tests/install-settings-test.sh, install.sh, linux/install.sh, linux/tests/install-linux-test.sh, mac/install.sh, mac/tests/install-mac-test.sh, pi/install.sh, pi/tests/install-herdr-fish-cleanup.sh, scripts/lib/herdr-app-settings.sh. Actual summary: Individual shell syntax/ShellCheck: 9 files passed. All nine bash -n checks passed too. This supersedes the earlier combined-context lint evidence; remote CI on the old pushed head still needs a coordinator push/new exact-head run.
- Final standalone focused suite and final existing CI-registered Mac runner both printed:
ok mac initial_and_preserved
ok mac read_only_and_skip
ok mac replacement_edges
ok mac config_home_precedence
ok mac custom_and_unsafe_homes
ok linux initial_and_preserved
ok linux read_only_and_skip
ok linux replacement_edges
ok linux config_home_precedence
ok linux custom_and_unsafe_homes
ok pi initial_and_preserved
ok pi read_only_and_skip
ok pi replacement_edges
ok pi config_home_precedence
ok pi custom_and_unsafe_homes
ok codespaces initial_and_preserved
ok codespaces read_only_and_skip
ok codespaces replacement_edges
ok codespaces config_home_precedence
ok codespaces custom_and_unsafe_homes
ok root_home_spellings
Herdr App settings tests: 21 passed, 0 failed
- Final bash mac/tests/install-mac-test.sh: ok install-mac tests passed; Ambient config overrides untouched PASS (mac).
- Final bash linux/tests/install-linux-test.sh: install-linux tests passed; Ambient config overrides untouched PASS (linux).
- Final bash pi/tests/install-herdr-fish-cleanup.sh: exit 0, all three cases invoked (not skipped; the script has no native success line); Ambient config overrides untouched PASS (pi).
- Each final platform harness was invoked with nonempty HERDR_APP_HOME and XDG_CONFIG_HOME pointing to its own disposable empty directories; the wrapper asserted no files/subdirectories appeared there. Mac retained its real-HOME read-only guard.
- Managed jq-1.8.2 exact-object assertion returned true. Original preferences/font/ligatures are retained with no font_size, ui_font or unsupported keys. git diff --check PASS. TUI, Brewfile, workflows and managed tool configuration unchanged PASS against supplied main base.
- AC2/3: all four actual installer paths cover six config-home precedence/empty/unset combinations, untouched nonwinning homes, actual repository settings links, byte-preserving backups and app-owned sentinels. Parent components are rejected with an actionable direct-absolute-path error before target writes/backups; layouts/.., layouts/../. and layouts/../mods/.. preserve the directory symlink, referent snapshot and backup inventory. Existing safe override/root, read-only/skip/force/idempotency cases still pass.
- AC5: README and Pi README now describe exact app-compatible nonempty override precedence, defaults and parent-component refusal, while retaining ownership/font-limit/layout/adoption guidance. Helper interface is unchanged: link_herdr_app_settings REPO_ROOT [REPLACE=true] [RUNNER=command] [BACKUP=herdr_app_backup_settings]. Default helper backups remain collision-safe adjacent settings.json.backup(.N); native Mac/Pi installer callbacks are unchanged.
- No push, workflow/policy change, package bootstrap, app-source edit or live config write in this round. Same-reviewer re-review of the new head, coordinator push/Copilot replies and re-review, exact-head green CI, merge/stable-checkout update and final live file-only adoption remain coordinator follow-ups.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
TASK-33 implementation is complete. Desktop font/ligature settings and file-only ownership remain intact across all four installers. CI/Copilot fix a0baf1d89afa9b72f50e3e2b88738c2405d3a6d0 honors nonempty HERDR_APP_HOME, then XDG_CONFIG_HOME/herdr-app, then HOME/.config/herdr-app; rejects whole parent-directory components without resolving away symlinks; and moves Codespaces timing callbacks into source-safe test setup so standalone CI lint passes. Added all-four-installer precedence and traversal regressions and isolated ambient overrides in temporary-home harnesses; related docs and Mac reporting are accurate. Pre-fix defects were reproduced. Final focused results: 21 passed, 0 failed. Individual ShellCheck 0.11.0 plus syntax passed nine files; final Mac/Linux/Pi harnesses and disposable ambient-isolation assertions passed; jq exact-object assertion returned true; diff/TUI/dependency/workflow checks passed unchanged. Helper signature/backups are unchanged. No push, app-source change or live config write. Coordinator owns same-reviewer re-review, PR #506 push/Copilot/comment handling, exact-head CI gate, merge/stable update and live adoption.
<!-- SECTION:FINAL_SUMMARY:END -->
