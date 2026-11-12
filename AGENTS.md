# Agent instructions

## Coordinator rules (primary Copilot session, or Pi root pane)
- These rules apply to the primary coordinator, not delegated agents. Workers
  implement only their brief; scouts/planners/reviewers stay in their roles and
  do not recursively delegate or own PR delivery. The coordinator plans and
  delegates; it does not edit source files itself.
- Break work into small, independent tasks with clear acceptance criteria, and
  track them in Backlog.md (see "Backlog.md task workflow" below).
- Use scout/explore/research to investigate before assigning implementation;
  use planner/rubber-duck for uncertain plans and fleet only for safe independent
  work, not every tool for trivial tasks. When a worker gets stuck, look at the
  failure yourself (test logs, result bundles,
  screenshots) and hand the next worker concrete root causes, not "try again".
- Use `worker` subagents for implementation. Before each worker, create a
  persistent branch and worktree named after the task
  (fetch `origin/main`, then
  `git worktree add ../sample-repo-task-12 -b task-12-short-slug origin/main`).
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
- After each worker finishes, start a reviewer/code-review on that branch/commit
  with the task spec. Copilot reviewers use read-only shell inspection; Pi
  reviewers must fetch every `review_git` output page. Push the branch
  and open a PR only on APPROVE or APPROVE WITH NOTES. Save each review where
  the next worker can read it, and send blocking items back in a fix round.
- Never weaken a check to make it pass: no audit/test exclusions, no hiding
  content, no stand-in UI for audits, no raised timeouts without a diagnosed
  cause. Fix the cause or stop and ask the owner.
- Product or scope decisions belong to the owner. Ask, record the answer in the
  task, and keep a decision visible in docs when it changes behaviour.
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
  rerun is flaky: track it as a task and fix the cause.
- Infrastructure failures (simulator hangs, runner killed before connecting)
  get one rerun before you treat them as code failures; say which it was.

## Pull request workflow (all agents)
Nothing reaches `main` directly. Every source change goes through a pull
request:
1. Work on the task branch (`task-12-short-slug`); task status changes ride in
   the same branch.
2. The coordinator pushes the branch and opens a PR titled
   `task-12: Short title` that names the Backlog task and lists the checks run.
3. After EVERY push, the coordinator requests/re-requests Copilot review using
   GraphQL `requestReviewsByLogin` with the PR node ID and
   `botLogins: ["copilot-pull-request-reviewer"]`, never a stale hardcoded bot ID.
   Inspect every review/comment/thread page; fix findings or respond with
   concrete reasoning and resolve all feedback. Push fixes and repeat local
   checks/review and current-head Copilot review until satisfied. Findings about
   unchanged code become To Do follow-up Backlog tasks, not silent scope changes.
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
   remove only owned clean inactive merged task worktrees.

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
  `backlog task edit task-12 -s "In Progress" -a @copilot-worker` (or `@pi-worker`
  for Pi), then research the code and record a short plan with `--plan` before
  writing code.
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
  (`--check-ac 1`), add notes, write `--final-summary`, and set `Done` as the
  branch's last task change. Leave criteria unchecked if they need evidence you
  don't have yet.
- If you're blocked, say so in the task notes, leave it `In Progress`, and tell
  the owner (subagents tell the coordinator).
- Refresh the CLI's managed instruction block with
  `backlog agents --update-instructions`. It only rewrites the text between its
  `BACKLOG.MD GUIDELINES` markers, so keep project rules outside them.

Tracking repo variant: when work spans several code repos, Backlog.md can live
in a separate meta repo that accepts direct task-state commits. Code repos stay
PR-only. Point agents at the meta repo with `BACKLOG_CWD`, and use one Backlog
project per code repo. In that variant, branch-based task rules do not apply:
task status does not ride in code PRs, and there are no `.backlog/` conflicts
where the code branch's version should win, because tasks live only in the
tracking repo.

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
- `.backlog/config.yml` starts with `---` for yamllint's document-start rule;
  `backlog config set` may rewrite the file without it, so re-run `yamllint .`
  after changing Backlog config.
- When editing Markdown instructions, check relevant README/AGENTS links. Never
  run broad `find`/`grep` commands above the repository root.
- The Backlog.md GitHub Project mirror is intentionally not configured during
  adoption: add `.backlog-sync.json`, the GitHub Project, and the launchd mirror
  agent only through the Backlog task titled "Mirror this repo's backlog to a
  GitHub Project with backlog-sync".

<!-- BACKLOG.MD GUIDELINES START -->
<!-- backlog.md-instructions-version: 1.53.0 -->
<CRITICAL_INSTRUCTION>

## Backlog.md Workflow

This project uses Backlog.md for task and project management.

**At the beginning of each conversation in this project, run `backlog instructions overview` before answering or taking action. Re-read it only if you have not read it yet in the current conversation.**

Use the overview to decide whether to search, read, create, or update Backlog tasks.

Before task lifecycle actions, read the matching detailed guide:
- `backlog instructions task-creation` before creating or splitting tasks
- `backlog instructions task-execution` before planning, changing status or assignee, adding a plan or implementation notes, or implementing task work
- `backlog instructions task-finalization` before checking acceptance criteria, writing final summaries, or moving tasks to terminal statuses

Use `backlog <command> --help` before running unfamiliar commands. Help shows options, fields, and examples.

Do not edit Backlog task, draft, document, decision, or milestone markdown files directly. Use the `backlog` CLI so metadata, relationships, and history stay consistent.

</CRITICAL_INSTRUCTION>
<!-- BACKLOG.MD GUIDELINES END -->
