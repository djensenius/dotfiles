---
id: TASK-33
title: Manage Herdr App font settings and safe config links
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-11-11T01:45:00Z'
updated_date: '2026-11-11T01:46:00Z'
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
