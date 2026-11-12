# Opt-in coordinator tick

Execute ONE reconciliation tick for the repositories and objective explicitly
authorized by the user. This text does not start a schedule. Before scheduling,
the coordinator must record the authorized absolute repository paths, objective,
dependency/task source, owned worktree/cache/log roots, any objective-scoped lock
paths, and the returned schedule ID. Initialize a session registry of returned
agent/session IDs, assigned tasks, worktree paths, state and last consumed
completion turn (empty at first). If authorization or this context is missing,
ask; never substitute another project's paths.

1. Reconcile known running IDs once using the available task/session tools
   (`/tasks` can show running work). Read each newly completed output once,
   record its consumed turn and outcome, and do not replay it next tick.
   Do not invent SQL tables, IDs, tool arguments or repeatedly poll in this tick.
   Inspect failures yourself and give concrete root causes to the next worker.
2. Refresh objective task/dependency state, branch/PR heads, exact-head review
   and CI evidence. Integrate completed work only through the personal and
   repository PR gates: local review, Copilot review after every push, all
   feedback addressed/resolved, completed current-head review and exact-head
   green checks, then head-guarded normal merge. Update and test main before
   launching dependent work. Head changes invalidate prior gates.
3. Measure free disk on the worktree/build filesystem; target at least 15 GiB.
   Below 15 GiB, reclaim safe owned artifacts before adding heavy work.
   Below 5 GiB, pause new heavy jobs; only safe cleanup and lightweight
   reconciliation may continue. Report remaining space and blockers.
   Inspect locks ONLY at configured objective-scoped paths; unknown locks are
   not stale. Serialize heavy builds using the repo's approved wrapper/lock,
   wait on active locks, never kill others' builds or boot extra simulators.
   Check wrapper cleanup semantics first: the shipped xbuild shuts down all
   simulators unless XBUILD_KEEP_SIMS=1; it does not guarantee owned-only cleanup.
   Use that opt-out on shared hosts and leave others' simulators untouched.
4. Cleanup only explicitly owned generated caches/logs or merged worktrees
   proven inactive and no longer needed for review/debugging. Confirm no active
   agent, process or build uses them; inspect worktree status and merge ancestry
   first. Remove clean merged worktrees with `git worktree remove`, never force.
   Preserve dirty/untracked work, branches under review, unknown artifacts and
   others' logs/caches. Never reset, rebase, force-push, weaken checks, bypass
   permissions or expand scope to free space.
5. Launch only dependency-ready, objective-scoped work from fresh `origin/main`,
   in persistent separate worktrees created before dispatch. Keep at most about
   five independent safe agents active (or the stricter repository limit),
   fewer for coupled files, disk constraints or trivial work. Serialize heavy
   builds even across otherwise parallel agents. Use research/planning/review
   roles proportionally; workers get bounded briefs and do not re-delegate.
   Record returned IDs immediately; do not relaunch already-running tasks.
6. Report consumed results, launched/running IDs, PR/review/CI state, disk and
   next dependencies. If everything is done, stop the known schedule through
   the available schedule controls and report completion. If genuinely blocked
   with no useful authorized next action, stop it and report the blocker and
   needed user decision/permission. Running jobs or pending review/CI are
   waiting, not automatically genuine blockers; leave the next tick to
   reconcile them. Never cancel unrelated schedules or abandon running work.

To opt in, enable experimental mode with `copilot --experimental` or
`/settings` experimental on, then use an ordinary natural-language prompt:

`/every 10m Read <absolute COPILOT_HOME>/prompts/coordinator-tick.md and execute one tick for the authorized repositories and objective recorded in this session.`

Replace the path with the actual personal directory. `/every [interval]
[prompt]` is experimental; this file is explicitly read text, not native prompt
discovery. Do not run the example or create a schedule without user authorization.
