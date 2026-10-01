---
id: TASK-4
title: Update CLI tool configuration for Pi and Herdr releases
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 16:54'
updated_date: '2026-10-01 16:54'
labels: []
dependencies: []
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The local cli-update report shows Pi, Herdr, Pi extensions, and related CLI packages have moved forward. Pi 0.99.x now includes built-in MCP/codemode support, Herdr 0.9.x adds useful config options and fixes key handling, and accidental local shell/script edits should be normalized before committing the dotfiles configuration.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 fish config does not duplicate PATH entries already managed by fish/conf.d/10-paths.fish, including LM Studio and ~/.local/bin.
- [ ] #2 gitconfig uses GitHub CLI credential helpers for github.com and gist.github.com without hard-coding an Apple Silicon Homebrew path.
- [ ] #3 The accidental root-level slack-webhook.sh helper is not added to the repository, and any Slack webhook setup documentation or helper changes are omitted from this task.
- [ ] #4 Pi agent-stack MCP configuration uses Pi built-in MCP config rather than pi-mcp-adapter, and docs/install code reference the new file and commands.
- [ ] #5 Pi shared settings use the system theme unless the existing docs or config show a stronger reason to keep a fixed dark theme.
- [ ] #6 Herdr 0.9 config changes are limited to useful non-conflicting settings; ctrl+s is not added as a prefix unless justified.
- [ ] #7 Relevant shell, Herdr, agent-stack, YAML, and TOML validations are run and reported.
<!-- AC:END -->
