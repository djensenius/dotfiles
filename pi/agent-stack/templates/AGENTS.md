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
  (`git worktree add ../<repo>-task-12 -b task-12-short-slug`) and launch the
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

## Backlog.md task workflow (all agents)
Backlog.md (`backlog/`) is the single source of truth for work. Any GitHub
issues or Project for it are a one-way mirror (e.g. `backlog-sync`); never track
work there except through the mirror's `inbox` label.

- At the start of a session run `backlog instructions overview`, and read
  `backlog instructions task-creation`, `task-execution` or `task-finalization`
  before creating, working on, or finishing tasks.
- Always use the `backlog` CLI to read and change tasks, with `--plain` for
  agent output (`--json` for scripts). Never create or edit files in `backlog/`
  directly. Pass task text with backticks as argv or single-quoted strings so the
  shell doesn't run it.
- Search first (`backlog search "<words>" --plain`) and don't create duplicates.
  New tasks need a description that says why the work exists, testable
  acceptance criteria (`--ac`), `--dep` for ordering, `-p` for subtasks, `-m`
  for milestones, and `-a` when the owner is known. No implementation plan at
  creation time.
- Before starting: pick a `To Do` task whose dependencies are `Done`, then
  `backlog task edit task-12 -s "In Progress" -a @<your-name>`. Research the
  code, then record a short plan with `--plan` before writing code.
- Put the task ID in the branch name and PR title (`task-12-short-slug`,
  "task-12: Short title"). Nested IDs keep every segment (`task-1.2.7-slug`).
- Task changes are auto-committed on the branch you run the CLI on. Update a
  branch's task only from that branch's worktree, never from main: `task list`
  and `task view` read only the current checkout, `backlog board` lets the
  current checkout's copy win, and `updated_date` has minute resolution, so
  edits on main can mask a task's real state.
- While working, use `--append-notes`. Out-of-scope work becomes a follow-up
  task or needs the owner's OK.
- When finished: verify each acceptance criterion with real evidence, check it
  (`--check-ac <n>`), add notes, write `--final-summary`, and move the task to
  `Done`. Leave criteria unchecked if they need evidence you don't have yet.
- If you're blocked, say so in the task notes, leave it `In Progress`, and tell
  the owner (subagents tell the coordinator).
- Refresh the CLI's managed instruction block with
  `backlog agents --update-instructions`. It only rewrites the text between its
  `BACKLOG.MD GUIDELINES` markers, so keep project rules outside them.

## Build and test rules (all agents)
- Never call `xcodebuild` directly. Always use `xbuild` with the same arguments;
  it serializes builds across all agents and cleans up simulators.
- Prefer one simulator destination per run; do not boot extra simulators.
- If a build is waiting on the lock, wait. Do not kill other builds.
- While iterating, run only the affected tests (`-only-testing`); run the full
  suites once on the final commit and report their per-test results.

## Project notes
<!-- Scheme names, test destinations, conventions, things agents get wrong. -->
