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
  fleet or every tool. Use the GitHub Issues-only workflow below for tracking.
- Use built-in explore/research, rubber-duck and code-review, or personal
  scout/planner/worker/reviewer agents as appropriate for uncertainty, plan
  critique, implementation and review. `/research <topic>` and `/review` are
  available; `/fleet <prompt>` suits genuinely independent subtasks.
- Coordinator-only rules do NOT turn delegated workers, scouts, planners,
  reviewers or task agents into coordinators. They follow their bounded brief,
  do not recursively delegate, push, open PRs or merge unless explicitly
  authorized for that action. Read-only roles remain read-only.
- Use persistent issue branches and worktrees for implementation. Fetch
  `origin/main` and create each new issue worktree from that fresh ref; finish
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

1. Review the actual diff locally on the full head SHA, run relevant checks,
   and require reviewer/code-review APPROVE or APPROVE WITH NOTES on that exact
   commit before pushing an issue branch and opening its bounded PR.
   `/pr` can assist, not replace these gates.
   Name branches `issue-N-short-slug` and PRs `issue508: Short title`, with
   `Closes #508` (or the appropriate fully qualified issue reference) and checks
   in the body. Existing branches for migrated work may retain their names.
2. After EVERY push, including feedback fixes and documentation-only commits,
   request/re-request Copilot review on that new head. Use GitHub GraphQL
   `requestReviewsByLogin(input: {pullRequestId: <PR node ID>,
   botLogins: ["copilot-pull-request-reviewer"]})`; do not hardcode a bot node ID.
   An automatic review counts only if actually completed for the current head.
   If review cannot be requested or verified, stop at the gate.
3. Read all review, comment and review-thread pages (follow pagination).
   Fix findings or respond with concrete reasoning, then resolve every feedback
   thread. Do not ignore medium/low feedback or mechanically resolve valid
   findings without addressing them. Out-of-scope findings require an explicit
   explanation and linked GitHub Issues for unchanged-code findings, not silent
   scope expansion. Other out-of-scope follow-up work needs owner approval.
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
   merged issue worktrees. Report evidence and genuine blockers.

## GitHub Issues-only tracking

GitHub Issues are the only authoritative work-tracking source. Do not maintain
any parallel local task file/database or mirrored task store. An ephemeral
session registry may track returned agent IDs and consumed results, but is not
a second task source. These defaults apply to shared Copilot/Pi coordination.

- Search existing open issues before creating work, for example
  `gh issue list --state open --search "words"`, and read the relevant issue
  with `gh issue view N --comments`. Reuse issues without duplicates; `inbox`
  issues are already issues, not inputs to another tracker.
- Issue descriptions explain why and contain testable acceptance criteria.
  After research and before editing, record a short plan. Record explicit
  dependencies, use sub-issues for bounded subtasks and fully qualified
  cross-repository issue links (`https://github.com/owner/repo/issues/N`).
  Never work in another repository without authorization.
- Comment In Progress updates, decisions, progress, actual check results,
  branch/PR links and blockers on the issue. No required labels, Projects or
  invented assignees. Keep issues open until delivery is complete.
- Do not create/start out-of-scope follow-up work without the owner's OK,
  except unchanged-code Copilot findings, which become linked GitHub Issues.
- Workers report evidence and blockers to the coordinator; they do not own
  PR delivery or close issues recursively. The coordinator verifies acceptance
  criteria with real evidence, records final results and owns finalization
  after merged delivery and successful canonical checks. Leave unsupported
  criteria unchecked. A failed-then-passing test is flaky: track it in an issue
  and fix the cause, never silently treat the rerun as clean evidence.

Scheduling is opt-in only. When explicitly authorized, read the personal
`prompts/coordinator-tick.md` asset as ordinary prompt text; it is not a native
Copilot prompt command or automatically discovered schedule.
