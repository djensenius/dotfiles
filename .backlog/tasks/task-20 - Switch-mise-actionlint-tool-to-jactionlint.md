---
id: TASK-20
title: Switch mise actionlint tool to jactionlint
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-13 21:47'
updated_date: '2026-10-13 21:56'
labels: []
dependencies: []
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
During macOS bootstrap, mise warns that `actionlint` is deprecated and recommends the maintained `jactionlint` fork. The workstation mise manifest should use the maintained replacement so future installs avoid the deprecation warning.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `mise/config.toml` uses `jactionlint` instead of deprecated `actionlint`.
- [ ] #2 Documentation or validation references still make clear how GitHub Actions linting is provided.
- [ ] #3 Relevant TOML/mise checks pass or are reported with evidence.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect mise/tool references for actionlint and jactionlint. 2. Replace the mise-managed deprecated actionlint entry with jactionlint only where that tool is declared. 3. Preserve validation guidance if the jactionlint install exposes the compatible actionlint command, updating docs/tests only if inspection shows stale mise-specific references. 4. Run TOML/mise/reference checks, record evidence, finalize, and commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented jactionlint migration: mise/config.toml now requests jactionlint 2.1.0; macOS Homebrew cleanup still targets the deprecated Homebrew actionlint formula but verifies the mise-managed jactionlint shim before uninstalling; README identifies jactionlint as the maintained GitHub Actions linter fork. Verified jactionlint install shape with an isolated mise install: release contains jactionlint, not actionlint, and jactionlint --version reported 2.1.0.
<!-- SECTION:NOTES:END -->
