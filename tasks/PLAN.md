# Agent stack plan

- [x] Preserve and complete the existing pinned Pi + Herdr agent-stack feature.
- [x] Apply the reviewed installer, reviewer, xbuild, and documentation fixes.
- [x] Complete the required syntax, lint, formatting, and mocked behavior checks.
- [x] Open pull request #348.
- [x] Address Copilot review comment 4118200679 with a constrained, repository-owned `review_git` tool.
- [x] Restrict `review_git` to committed-object inspection and harden it against Git configuration injection.
- [x] Validate hostile filters, diff drivers, pagers, fsmonitor, helpers, and `GIT_*` variables without side effects.
- [x] Require Git 2.45.0, full commit IDs, and explicit no-lazy-fetch execution.
- [x] Replace output truncation with bounded, complete pagination and adversarial regression coverage.
- [x] Preserve text hunks and committed gitlink pointer changes in reviewer show/diff output.
- [x] Address Copilot review comment 4118771209 by routing installer runtimes through the project mise environment with mocked idempotency coverage.
- [x] Address the Copilot fail-fast review for macOS `lockf` and Pi package inspection failures.
- [ ] Push the follow-up commits and complete Copilot review.
- [ ] Confirm CI passes for the follow-up commits.
