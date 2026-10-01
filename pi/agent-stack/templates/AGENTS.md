# Agent instructions

## Coordinator rules (the Pi session in the root pane)
- You are the coordinator. Plan and delegate; do not edit source files yourself.
- Break work into small, independent tasks with clear acceptance criteria, and
  track them in Backlog.md (see "Backlog.md task workflow" below).
- Use a `scout` subagent to investigate before assigning implementation. When a
  worker gets stuck, look at the failure yourself (test logs, result bundles,
  screenshots) and hand the next worker concrete root causes, not "try again".
- Use `worker` subagents for implementation. Before each worker, create a
  persistent branch and worktree named after the task
  (`git worktree add ../sample-repo-task-12 -b task-12-short-slug`) and launch the
  worker with `cwd` set to that worktree. Create the worktree in a separate step
  that finishes before the launch; a workflow started in the same step can fail
  with "cwd does not exist". Do not use managed `worktree: true` runs here: they
  return a patch and delete their branch, which breaks branch review.
- Run workers one at a time unless the owner allows parallel lanes. Parallel
  lanes need separate worktrees and disjoint files. Generated project files
  (e.g. XcodeGen output) are regenerated, never hand-merged.
- Keep worker scope small. If a worker runs out of time or reports partial
  work, split the rest into smaller sequential workers instead of re-sending the
  same large brief.
- Each worker commits in logical steps (never amends) and reports the branch,
  full 40-character commit SHA, files, and the checks it ran with their actual
  output lines (per-test pass/fail for test suites), not just "passed".
- After each worker finishes, start a `reviewer` on that branch/commit with the
  task spec. Require it to fetch every `review_git` output page. Only integrate
  on APPROVE or APPROVE WITH NOTES. Save each review where the next worker can
  read it, and send blocking items back in a fix round.
- Never weaken a check to make it pass: no audit/test exclusions, no hiding
  content, no stand-in UI for audits, no raised timeouts without a diagnosed
  cause. Fix the cause or stop and ask the owner.
- Product or scope decisions belong to the owner. Ask, record the answer in the
  task, and keep a decision visible in docs when it changes behaviour.
- After integrating: build and run tests on the main checkout before pushing or
  starting any dependent worker. Gate the push on the checks' exit codes, not
  on reading the output afterwards. A test that fails once and passes on rerun
  is flaky: track it as a task and fix the cause.
- Infrastructure failures (simulator hangs, runner killed before connecting)
  get one rerun before you treat them as code failures; say which it was.
- Then remove the task worktree with `git worktree remove` and push finished
  branches to `origin` so work is not only in worktrees.

## Pull request workflow (all agents)
Nothing reaches `main` directly. Every source change goes through a pull
request:
1. Work on the task branch (`task-12-short-slug`); task status changes ride in
   the same branch.
2. Push the branch and open a PR titled `task-12: Short title` that names the
   Backlog task and lists the checks run.
3. Automatic Copilot code review and CI must run before merge. Address findings,
   push fixes, reply on each comment, and request a new Copilot review.
4. Review-loop stopping rule: fix high-severity findings and re-request review.
   Medium/low or not-applicable findings are fixed or answered with reasoning
   and resolved. Findings about code the PR didn't change become To Do follow-up
   Backlog tasks. Merge when the latest Copilot review has no unresolved
   high-severity findings and CI is green.
5. Either the owner or the coordinator merges. Afterwards, update the main
   checkout, re-run the checks, and remove the task worktree.

## Backlog.md task workflow (all agents)
Backlog.md (`.backlog/`) is the single source of truth for work. Initialize it
with `backlog init --backlog-dir .backlog`, then run
`backlog config set autoCommit true` and
`backlog config set checkActiveBranches true`. Any GitHub Project mirrored by
[backlog-sync](https://github.com/djensenius/backlog-sync) is the live board;
`backlog board` on main catches up when PRs merge. Do not track work on GitHub
except through triaged issues labelled `inbox`.

- At the start of a session run `backlog instructions overview`, and read
  `backlog instructions task-creation`, `task-execution` or `task-finalization`
  before creating, working on, or finishing tasks. Also check GitHub issues
  labelled `inbox`, search for existing tasks first, triage each issue into a
  task, then remove the label.
- Always use the `backlog` CLI to read and change tasks, with `--plain` for
  agent output (`--json` for scripts). Never create or edit files in `.backlog/`
  directly. Pass task text with backticks as argv or single-quoted strings so the
  shell doesn't run it.
- Search first (`backlog search "words" --plain`) and don't create duplicates.
  New tasks need a description that says why the work exists, testable
  acceptance criteria (`--ac`), `--dep` for ordering, `-p` for subtasks, `-m`
  for milestones, and `-a` when the owner is known. No implementation plan at
  creation time.
- Start a task from its own branch. In that branch's worktree, run
  `backlog task edit task-12 -s "In Progress" -a @pi-worker`, then research the
  code and record a short plan with `--plan` before writing code.
- Put the task ID in the branch name and PR title (`task-12-short-slug`,
  `task-12: Short title`). Nested IDs keep every segment (`task-1.2.7-slug`).
- Task changes are auto-committed on the branch you run the CLI on. Once a task
  is In Progress, make every further change (plan, notes, checked criteria,
  final summary, Done) from its worktree, so it reaches main with the merge.
  Don't edit that task on main while its branch is open: `task list` and
  `task view` read only the current checkout, `backlog board` lets the current
  checkout's copy win, and `updated_date` has minute resolution, so edits on
  main can mask the branch's state. If a merge conflicts only in a `.backlog/`
  task file, keep the branch's version.
- While working, use `--append-notes`. Do not add out-of-scope work, create a
  follow-up task, or start a follow-up task without the owner's OK. Exception:
  Copilot findings about unchanged code become To Do follow-up Backlog tasks.
- When finished: verify each acceptance criterion with real evidence, check it
  (`--check-ac 1`), add notes, write `--final-summary`, and move the task to
  `Done`. Leave criteria unchecked if they need evidence you don't have yet.
- If you're blocked, say so in the task notes, leave it `In Progress`, and tell
  the owner (subagents tell the coordinator).
- Refresh the CLI's managed instruction block with
  `backlog agents --update-instructions`. It only rewrites the text between its
  `BACKLOG.MD GUIDELINES` markers, so keep project rules outside them.

Tracking repo variant: when work spans several code repos, Backlog.md can live
in a separate meta repo that accepts direct task-state commits. Code repos stay
PR-only. Point agents at the meta repo with `BACKLOG_CWD`, and use one Backlog
project per code repo.

## Build and test rules (all agents)
- Never call `xcodebuild` directly. Always use `xbuild` with the same arguments;
  it serializes builds across all agents and cleans up simulators.
- Prefer one simulator destination per run; do not boot extra simulators.
- If a build is waiting on the lock, wait. Do not kill other builds.
- While iterating, run only the affected tests (`-only-testing`); run the full
  suites once on the final commit and report their per-test results.

## Project notes
<!-- Scheme names, test destinations, conventions, things agents get wrong. -->
