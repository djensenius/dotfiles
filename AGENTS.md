# Agent instructions

## Coordinator rules (primary Copilot session, or Pi root pane)
- These rules apply to the primary coordinator, not delegated agents. Workers
  implement only their brief; scouts/planners/reviewers stay in their roles and
  do not recursively delegate or own PR delivery. The coordinator plans and
  delegates; it does not edit source files itself.
- Break work into small, independent tasks with clear acceptance criteria, and
  track them in GitHub Issues (see "GitHub Issues workflow" below).
- Use scout/explore/research to investigate before assigning implementation;
  use planner/rubber-duck for uncertain plans and fleet only for safe independent
  work, not every tool for trivial tasks. When a worker gets stuck, look at the
  failure yourself (test logs, result bundles,
  screenshots) and hand the next worker concrete root causes, not "try again".
- Use `worker` subagents for implementation. Before each worker, create a
  persistent branch and worktree named after the issue
  (fetch `origin/main`, then
  `git worktree add ../sample-repo-issue-508 -b issue-508-short-slug origin/main`).
  Give the worker the absolute worktree path and require shell commands to
  start with `cd` there. Pi supports `cwd`; Copilot's task tool does not.
  Copilot `/new worktree` or `/fork worktree` sessions are also available.
  Create the worktree in a separate step that finishes before the launch; a
  workflow started in the same step can fail with "cwd does not exist".
  Do not use Pi's managed `worktree: true` runs here: they
  return a patch and delete their branch, which breaks branch review.
- Use proportional parallelism, at most about five safe independent agents
  within the authorized objective; serialize when files/dependencies overlap.
  Parallel lanes need separate worktrees and disjoint files. Generated project files
  (e.g. XcodeGen output) are regenerated, never hand-merged.
- Keep worker scope small. If a worker runs out of time or reports partial
  work, split the rest into smaller sequential workers instead of re-sending the
  same large brief.
- Each worker commits in logical steps (never amends) and reports the branch,
  full 40-character commit SHA, files, and the checks it ran with their actual
  output lines (per-test pass/fail for test suites), not just "passed".
- After each worker finishes, start a reviewer/code-review on the full 40-character
  head SHA with the issue spec. Copilot reviewers use read-only shell inspection; Pi
  reviewers must fetch every `review_git` output page. Push the branch
  and open a PR only on APPROVE or APPROVE WITH NOTES for that exact head. Save each review where
  the next worker can read it, and send blocking items back in a fix round.
- Never weaken a check to make it pass: no audit/test exclusions, no hiding
  content, no stand-in UI for audits, no raised timeouts without a diagnosed
  cause. Fix the cause or stop and ask the owner.
- Product or scope decisions belong to the owner. Ask, record the answer in the
  issue, and keep a decision visible in docs when it changes behaviour.
- Routine execution, feedback fixes and gated normal merges are autonomous
  within the authorized repositories/objective. Never bypass permissions,
  reset/rebase/force-push, discard dirty work or silently broaden scope.
- Scheduling is opt-in only. Copilot personal defaults live in
  `$COPILOT_HOME/instructions/dotfiles-coordinator.instructions.md`
  (`COPILOT_HOME` defaults to `~/.copilot`). Explicitly read
  `$COPILOT_HOME/prompts/coordinator-tick.md` in an authorized experimental
  `/every [interval] [prompt]`; this is ordinary text, not native prompt discovery.
  The tick tracks returned IDs/consumed completions once, dependency-ready work,
  >=15 GiB disk target, no new heavy jobs below 5 GiB, serialized builds and
  only owned inactive cleanup. Inspect only configured objective locks; stop
  the known schedule when done or genuinely blocked. Never start one implicitly.
- After the PR merges, update the main checkout and run the checks before
  starting any dependent worker. Gate dependent work on the checks' exit codes,
  not on reading the output afterwards. A test that fails once and passes on
  rerun is flaky: track it as a GitHub Issue and fix the cause.
- Infrastructure failures (simulator hangs, runner killed before connecting)
  get one rerun before you treat them as code failures; say which it was.

## Pull request workflow (all agents)
Nothing reaches `main` directly. Every source change goes through a pull
request:
1. Work on the issue branch (`issue-508-short-slug`).
2. The coordinator pushes the branch and opens a PR titled
   `issue508: Short title` with `Closes #508` and the checks run in its body.
3. After EVERY push, the coordinator requests/re-requests Copilot review using
   GraphQL `requestReviewsByLogin` with the PR node ID and
   `botLogins: ["copilot-pull-request-reviewer"]`, never a stale hardcoded bot ID.
   Inspect every review/comment/thread page; fix findings or respond with
   concrete reasoning and resolve all feedback. Push fixes and repeat local
   checks/review and current-head Copilot review until satisfied. Findings about
   unchanged code become follow-up GitHub Issues, not silent scope changes.
4. Immediately before merge, freshly verify the full PR head SHA, a completed
   Copilot review recorded on that exact commit, satisfactory addressed feedback,
   no unresolved threads/outstanding change requests and all relevant
   required/expected checks successful on that exact head. Pending, missing,
   skipped, neutral, cancelled or failed checks are not green. A head change
   invalidates all gates. Missing evidence/permission blocks merge.
5. The coordinator normally merges autonomously with
   `gh pr merge --merge --match-head-commit <full-head-SHA>` (or the owner merges).
   No admin bypass or history rewriting. Update main by normal fast-forward/
   merge without discarding local changes, re-run checks successfully, then
   remove only owned clean inactive merged issue worktrees.

## GitHub Issues workflow (all agents)
GitHub Issues are the only authoritative work-tracking source for Copilot and
Pi. Do not maintain a parallel local task file/database or mirrored task store.
An ephemeral session registry may track running agents and consumed results;
it is not a second task source.

- At session start, search existing open issues before creating work, for example
  `gh issue list --state open --search "words"`. Read the relevant issue with
  `gh issue view 508 --comments`. Reuse existing issues; `inbox` issues are
  already issues, not inputs to another tracker. No labels, Projects or invented
  assignees are required by this workflow.
- Each issue describes why the work exists, testable acceptance criteria as
  checkboxes, and a short implementation plan recorded after research and before
  editing. Record explicit dependencies and use sub-issues for bounded subtasks;
  cross-repository dependencies must use fully qualified issue links
  (`https://github.com/owner/repo/issues/N`). Work only in authorized repositories.
- Use an issue-named persistent branch/worktree (`issue-508-short-slug`, or
  `issue-N-short-slug` for another issue). Existing branches for migrated work
  may retain their names. Record the branch and PR in the issue.
- Use issue comments for In Progress updates, decisions, progress, actual check
  results and blockers. Keep the issue open until delivery is complete. Blocked
  workers report to the coordinator; do not invent a required status label.
- Do not add out-of-scope work or create/start follow-up issues without the
  owner's OK. Exception: Copilot findings about unchanged code become follow-up
  GitHub Issues, linked from the review with a concrete scope explanation.
- Workers implement only their brief and report evidence; they do not own PR
  delivery or close issues recursively. The coordinator verifies each acceptance
  criterion with real evidence, records the final summary/results, and owns issue
  finalization after merged delivery and successful canonical checks. Leave
  criteria unchecked when evidence is missing. PRs use `Closes #508` (or the
  appropriate fully qualified issue reference) to link merged delivery.

## Build and test rules (all agents)
- Never call `xcodebuild` directly. Always use `xbuild` with the same arguments;
  it serializes builds across all agents and cleans up simulators.
- Prefer one simulator destination per run; do not boot extra simulators.
- If a build is waiting on the lock, wait. Do not kill other builds.
- On shared hosts, use `XBUILD_KEEP_SIMS=1`: the shipped wrapper otherwise
  shuts down all simulators, not just owned ones. Leave others' resources alone.
- While iterating, run only the affected tests (`-only-testing`); run the full
  suites once on the final commit and report their per-test results.

## Project notes
- This repository is `djensenius/dotfiles`, a dotfiles/bootstrap repo for fish,
  Neovim, tmux, Herdr, macOS, Raspberry Pi, and GitHub Codespaces setup.
- Setup entry points: `./install.sh` for Codespaces, `./install-mac` for macOS,
  `./install-pi` for Raspberry Pi, `./install-linux` for supported
  Arch/Ubuntu/Debian-family Linux hosts, and `./ai-tools/install.sh` for the
  generalized AI/coding-agent tooling documented in the README coordinator
  section. `./install-agent-stack` remains only as a compatibility wrapper.
- Required validation from `.github/copilot-instructions.md`: run `yamllint .`
  after YAML changes; run `pip install tomllint && for f in **/*.toml; do [ -f
  "$f" ] && tomllint "$f"; done` after TOML changes; run `curl -L
  https://github.com/rhysd/actionlint/releases/latest/download/actionlint_1.7.7_linux_amd64.tar.gz
  | tar xzf - actionlint && ./actionlint` after GitHub Actions changes.
- AI/coding-agent tooling checks live under `ai-tools/tests/`; the footer/status
  extension is tested with `node ai-tools/tests/subagent-status.test.ts`.
  Shell/security checks there include `install-git-version.sh`,
  `install-runtime.sh`, and `reviewer-git-security.sh`; run them with
  `bash ai-tools/tests/<name>.sh`. Generic Linux installer checks live under
  `linux/tests/`.
- The template's Xcode/`xbuild` build rules above don't apply here: this repo
  has no Apple project (it only ships the `xbuild` wrapper for other repos).
- When editing Markdown instructions, check relevant README/AGENTS links. Never
  run broad `find`/`grep` commands above the repository root.
