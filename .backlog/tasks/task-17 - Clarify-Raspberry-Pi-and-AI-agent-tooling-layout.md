---
id: TASK-17
title: Clarify Raspberry Pi and AI agent tooling layout
status: To Do
assignee: []
created_date: '2026-10-13 19:24'
updated_date: '2026-10-13 19:30'
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
- [ ] #1 Raspberry Pi device provisioning files are named and documented distinctly from AI/agent tooling files.
- [ ] #2 The agent tooling directory and entry point names avoid being specific to only Pi or Herdr unless the file is actually Pi- or Herdr-specific.
- [ ] #3 Existing documented entry points continue to work, either directly or through compatibility wrappers with deprecation guidance.
- [ ] #4 README and installer references are updated consistently.
- [ ] #5 Relevant installer/link/test checks pass or any limitations are reported with evidence.
- [ ] #6 After Raspberry Pi setup completes, the user sees guidance that `./install-pi --ai-tools` installs the full AI/coding-agent tooling stack.
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision: use `ai-tools/` as the generalized root for AI/coding-agent tooling when cleaning up the current Pi/Herdr agent-stack layout.

Owner request: after Raspberry Pi setup completes, the installer/docs should tell the user that running the Raspberry Pi installer with `--ai-tools` is how to install the full AI/coding-agent tooling stack on that machine.

Owner decision: do not broaden Raspberry Pi setup into a generic Linux/distro/architecture installer for now. Keep the cleanup focused on human clarity: Raspberry Pi OS/device setup remains Raspberry Pi-specific, while AI/coding-agent tooling moves under the generalized `ai-tools/` naming.
<!-- SECTION:NOTES:END -->
