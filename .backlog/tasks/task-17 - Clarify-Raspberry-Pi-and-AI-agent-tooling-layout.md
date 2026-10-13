---
id: TASK-17
title: Clarify Raspberry Pi and AI agent tooling layout
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-13 19:24'
updated_date: '2026-10-13 19:53'
labels: []
dependencies: []
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The repository currently stores both Raspberry Pi device provisioning and the Pi/Herdr coding-agent stack under `pi/`, which overloads “Pi” for humans. The owner wants the layout and naming cleaned up, and wants the agent-tooling area generalized so future AI tools can be added or swapped without making the directory names misleading.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Raspberry Pi device provisioning files are named and documented distinctly from AI/agent tooling files.
- [x] #2 The agent tooling directory and entry point names avoid being specific to only Pi or Herdr unless the file is actually Pi- or Herdr-specific.
- [x] #3 Existing documented entry points continue to work, either directly or through compatibility wrappers with deprecation guidance.
- [x] #4 README and installer references are updated consistently.
- [x] #5 Relevant installer/link/test checks pass or any limitations are reported with evidence.
- [x] #6 After Raspberry Pi setup completes, the user sees guidance that `./install-pi --ai-tools` installs the full AI/coding-agent tooling stack.
- [x] #7 A Linux setup entry point supports at least Arch, Ubuntu, and Debian families, with distro-specific package-manager handling or clear guarded messaging for unsupported distros.
- [x] #8 The Raspberry Pi setup remains clearly identified as Raspberry Pi-specific even if it shares Linux helper code with the broader Linux installer.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Move the current Pi/Herdr agent-stack files to a generalized root ai-tools/ path, update installer path calculations, tests, wrappers, and documentation references while preserving ./install-agent-stack as a forwarding compatibility entry point. 2. Keep pi/ as Raspberry Pi device setup: add ./install-pi/ pi/install.sh --ai-tools flow that runs ai-tools/install.sh after Pi provisioning and always prints the post-run guidance for the full AI/coding-agent stack. 3. Add a guarded ./install-linux entry point with linux/install.sh distro-family detection for Arch and Debian/Ubuntu package baselines plus safe dotfile/mise/ai-tools integration controls, with tests for detection, package manager use, and unsupported distro messaging. 4. Update README.md, pi/README.md, AGENTS/project references, and targeted tests to the new ai-tools paths, then run the requested shell/node/docs checks and commit the implementation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision: use `ai-tools/` as the generalized root for AI/coding-agent tooling when cleaning up the current Pi/Herdr agent-stack layout.

Owner request: after Raspberry Pi setup completes, the installer/docs should tell the user that running the Raspberry Pi installer with `--ai-tools` is how to install the full AI/coding-agent tooling stack on that machine.

Owner decision: do not broaden Raspberry Pi setup into a generic Linux/distro/architecture installer for now. Keep the cleanup focused on human clarity: Raspberry Pi OS/device setup remains Raspberry Pi-specific, while AI/coding-agent tooling moves under the generalized `ai-tools/` naming.

Owner scope update: include a Linux installer path for common Arch, Ubuntu, and Debian distros as part of the layout cleanup. The earlier “do not broaden Linux support” decision is superseded for TASK-17.

Implemented on commit e505188: moved pi/agent-stack to ai-tools with installer/test path updates; kept install-agent-stack as a deprecated forwarding wrapper; added install-pi --ai-tools plus final guidance; added install-linux/linux/install.sh for Debian/Ubuntu apt and Arch pacman families with unsupported-distro guard; updated README.md, pi/README.md, AGENTS.md, and task plan references. Validation passed: bash ai-tools/tests/install-runtime.sh; bash ai-tools/tests/install-git-version.sh; node ai-tools/tests/subagent-status.test.ts; MISE_IGNORED_CONFIG_PATHS="$HOME/.config/mise/config.toml" bash ai-tools/tests/reviewer-git-security.sh; bash linux/tests/install-linux-test.sh; bash pi/tests/install-ai-tools-guidance.sh; bash pi/tests/install-herdr-fish-cleanup.sh; shellcheck changed shell scripts; pi/install.sh --help and linux/install.sh --help; git grep found no remaining pi/agent-stack references outside historical .backlog tasks; git diff --check. Note: reviewer-git-security.sh without the MISE_IGNORED_CONFIG_PATHS guard failed because this workstation global ~/.config/mise/config.toml has a duplicate actionlint key; the guarded rerun isolates the repo config and passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Generalized the former pi/agent-stack layout to ai-tools, retained ./install-agent-stack as a deprecated compatibility wrapper, added Raspberry Pi --ai-tools installation/guidance, added a guarded ./install-linux path for Debian/Ubuntu and Arch families, and updated README/AGENTS/tests to the new layout. Verified with the moved ai-tools shell/node/security tests, new Linux and Raspberry Pi guidance tests, help output checks, shellcheck, reference sweep, and git diff --check.
<!-- SECTION:FINAL_SUMMARY:END -->
