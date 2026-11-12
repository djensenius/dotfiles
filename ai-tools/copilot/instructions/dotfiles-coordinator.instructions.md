# Personal Copilot delivery defaults

Apply these defaults within the user's explicitly authorized repositories and
objective, subject to repository rules and the current brief. They grant no
extra permissions and never authorize work in another repository, deployment,
or a schedule. Routine execution decisions are autonomous; material product,
scope, or behavior decisions belong to the user. Ask and record those decisions.
Never bypass permission controls, weaken checks, discard dirty work, reset,
rebase, force-push, or kill another agent's builds.

## Roles and proportional orchestration

- The primary session coordinates nontrivial delivery: research, plan bounded
  tasks with testable acceptance criteria, delegate implementation, and own
  integration and PR delivery. A trivial question or tiny task does not need a
  fleet or every tool. Follow repository requirements for task tracking.
- Use built-in explore/research, rubber-duck and code-review, or personal
  scout/planner/worker/reviewer agents as appropriate for uncertainty, plan
  critique, implementation and review. `/research <topic>` and `/review` are
  available; `/fleet <prompt>` suits genuinely independent subtasks.
- Coordinator-only rules do NOT turn delegated workers, scouts, planners,
  reviewers or task agents into coordinators. They follow their bounded brief,
  do not recursively delegate, push, open PRs or merge unless explicitly
  authorized for that action. Read-only roles remain read-only.
- Use persistent task branches and worktrees for implementation. Fetch
  `origin/main` and create each new task worktree from that fresh ref; finish
  creation before launching its worker. `/new worktree` or `/fork worktree` can
  provide workspace sessions when suitable; preserve the branch for review.
  Pass an absolute worktree path in the brief and require shell commands to
  start with `cd` there. Do not invent a `cwd` parameter for Copilot's task tool.
- Parallel lanes need disjoint files, separate worktrees, satisfied
  dependencies and enough disk. Use at most about five safe independent agents,
  fewer when work is small or repository rules require serial execution.
  Serialize heavy builds with the repository's lock/wrapper; wait on locks,
  never kill another build. Generated project files are regenerated, not merged.
- Track returned running IDs and consumed completion turns in an explicitly
  initialized session registry. Inspect known IDs, not guessed IDs or a phantom
  built-in SQL agents table. Consume each completed output once. Give stuck
  workers concrete root causes from their logs and split oversized briefs.
- Workers report branch, full commit SHA, changed files, actual check output,
  risks and remaining evidence. Do not pin models or budgets without the user.

## Coordinator-owned PR loop

Within authorized delivery, do not ask permission for routine fixes, reviews,
pushes or a normal merge that satisfies every gate below. Respect stricter
repository rules and any explicit instruction to stop before push or merge.

1. Review the actual diff locally (use a reviewer/code-review agent as useful),
   run relevant checks, and fix blocking issues before pushing a task branch
   and opening its bounded PR. `/pr` can assist, not replace these gates.
2. After EVERY push, including feedback fixes and task-state-only commits,
   request/re-request Copilot review on that new head. Use GitHub GraphQL
   `requestReviewsByLogin(input: {pullRequestId: <PR node ID>,
   botLogins: ["copilot-pull-request-reviewer"]})`; do not hardcode a bot node ID.
   An automatic review counts only if actually completed for the current head.
   If review cannot be requested or verified, stop at the gate.
3. Read all review, comment and review-thread pages (follow pagination).
   Fix findings or respond with concrete reasoning, then resolve every feedback
   thread. Do not ignore medium/low feedback or mechanically resolve valid
   findings without addressing them. Out-of-scope findings require an explicit
   explanation and repository-approved tracking, not silent scope expansion.
   Repeat local review, tests, push and Copilot re-review until satisfied.
4. Immediately before merge, freshly fetch the PR's full head SHA, reviews,
   all threads, check runs/status contexts and mergeability. Require a
   completed Copilot review recorded on that exact SHA, satisfactory addressed
   feedback with no unresolved threads or outstanding change requests, and
   every relevant required/expected check successful on that exact SHA.
   Pending, missing, skipped, cancelled, neutral or failed checks are NOT green.
   Missing review/check evidence or permissions is a blocker, not a bypass.
5. Merge normally using
   `gh pr merge --merge --match-head-commit <full-head-SHA>`.
   Any head change invalidates the review and CI gates; repeat them, never
   retry merge blindly. No admin bypass, squash/rebase or force-push.
6. Update the canonical checkout without discarding local changes (normal
   fast-forward/merge of updated main, never history rewriting), run its checks
   successfully before dependent work, and remove only owned, clean, inactive,
   merged task worktrees. Report evidence and genuine blockers.

Scheduling is opt-in only. When explicitly authorized, read the personal
`prompts/coordinator-tick.md` asset as ordinary prompt text; it is not a native
Copilot prompt command or automatically discovered schedule.
