// Unit test for extensions/subagent-status.ts using a fake Pi event bus.
// Run: node pi/agent-stack/tests/subagent-status.test.ts
import subagentStatus, { activeSubagentCount, fleetActivity, formatSubagentStatus, STATUS_KEY } from "../extensions/subagent-status.ts";

type Handler = (data: unknown) => void;

function assert(condition: unknown, message: string): asserts condition {
	if (!condition) throw new Error(message);
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function createHarness(opts: { respond?: boolean } = {}) {
	const bus = new Map<string, Set<Handler>>();
	const lifecycle = new Map<string, (event: unknown, ctx: unknown) => Promise<void> | void>();
	const statuses: Array<string | undefined> = [];
	let children = 0;
	let workflows = 0;
	let requests = 0;

	const events = {
		on(name: string, handler: Handler) {
			if (!bus.has(name)) bus.set(name, new Set());
			bus.get(name)!.add(handler);
			return () => bus.get(name)?.delete(handler);
		},
		emit(name: string, data: unknown) {
			for (const handler of [...(bus.get(name) ?? [])]) handler(data);
		},
	};

	// Fake pi-subagents RPC responder.
	events.on("subagents:rpc:v1:request", (request) => {
		const { requestId, method } = request as { requestId: string; method: string };
		requests++;
		if (opts.respond === false || method !== "status") return;
		queueMicrotask(() =>
			events.emit(`subagents:rpc:v1:reply:${requestId}`, {
				version: 1,
				requestId,
				success: true,
				data: {
					fleet: {
						version: 1,
						entries: [
							...Array.from({ length: workflows }, (_, i) => ({ key: `wf-${i}`, agent: "workflow" })),
							...Array.from({ length: children }, (_, i) => ({ key: `c-${i}`, agent: "scout" })),
						],
						totalActive: workflows + children,
						omitted: 0,
					},
				},
			}),
		);
	});

	const pi = {
		events,
		on(name: string, handler: (event: unknown, ctx: unknown) => Promise<void> | void) {
			lifecycle.set(name, handler);
		},
	};

	let seq = 0;
	subagentStatus(pi as never, { rpcTimeoutMs: 50, refreshMs: 20, newRequestId: () => `req-${++seq}` });

	const ctx = (hasUI: boolean, onSet?: () => void) => ({
		hasUI,
		ui: {
			setStatus(key: string, text: string | undefined) {
				assert(key === STATUS_KEY, `unexpected status key ${key}`);
				onSet?.();
				statuses.push(text);
			},
		},
	});

	return {
		events,
		statuses,
		get requests() {
			return requests;
		},
		setActive(n: number, workflowRuns = 0) {
			children = n;
			workflows = workflowRuns;
		},
		start: (hasUI = true, onSet?: () => void) => lifecycle.get("session_start")!({}, ctx(hasUI, onSet)),
		shutdown: () => lifecycle.get("session_shutdown")!({}, undefined),
		agentStart: () => lifecycle.get("agent_start")!({}, undefined),
		last: () => statuses[statuses.length - 1],
	};
}

async function main() {
	// Formatting.
	assert(formatSubagentStatus(0, false) === undefined, "zero active should show nothing");
	assert(formatSubagentStatus(1, false) === "⚙ 1 subagent", "singular label");
	assert(formatSubagentStatus(3, false) === "⚙ 3 subagents", "plural label");
	assert(formatSubagentStatus(2, true) === "⚠ 2 subagents", "attention label");

	// Fleet counting: workflow wrappers are not subagents; omitted entries count.
	assert(
		activeSubagentCount({ entries: [{ agent: "workflow" }, { agent: "scout" }], totalActive: 2, omitted: 0 }) === 1,
		"a one-step workflow is one subagent, not two",
	);
	assert(
		activeSubagentCount({ entries: [{ agent: "workflow" }, ...Array(5).fill({ agent: "worker" })], totalActive: 6, omitted: 0 }) === 5,
		"a workflow with five children shows five",
	);
	// Truncated list: omitted entries may be workflow wrappers, so the visible
	// subagent count is a lower bound shown as "N+".
	{
		const activity = fleetActivity({ entries: Array(16).fill({ agent: "worker" }), totalActive: 20, omitted: 4 });
		assert(activity?.subagents === 16 && activity.atLeast === true, "truncated fleet is a lower bound of visible subagents");
		assert(formatSubagentStatus(activity.subagents, false, activity.busy, activity.atLeast) === "⚙ 16+ subagents", "lower bound renders as N+");
		const withWrapper = fleetActivity({
			entries: [{ agent: "workflow" }, ...Array(15).fill({ agent: "worker" })],
			totalActive: 18,
			omitted: 2, // could include another workflow wrapper
		});
		assert(withWrapper?.subagents === 15 && withWrapper.atLeast, "an omitted wrapper is never counted as a subagent");
		assert(formatSubagentStatus(1, false, 1, true) === "⚙ 1+ subagents", "lower bound uses plural");
	}
	assert(activeSubagentCount({ totalActive: 3 }) === 3, "falls back to totalActive without entries");
	assert(activeSubagentCount(undefined) === undefined, "missing fleet is unknown");

	// Restores the count at session start and follows lifecycle events.
	{
		const h = createHarness();
		h.setActive(2);
		await h.start();
		assert(h.last() === "⚙ 2 subagents", `session start should restore count, got ${h.last()}`);

		h.setActive(3, 1); // a workflow run with three children: still three subagents
		h.events.emit("subagent:async-started", { id: "run-b" });
		await sleep(5);
		assert(h.last() === "⚙ 3 subagents", `started event should refresh, got ${h.last()}`);

		// Workflow children change without top-level events: periodic refresh catches it.
		h.setActive(5);
		await sleep(60);
		assert(h.last() === "⚙ 5 subagents", `periodic refresh should update count, got ${h.last()}`);

		h.events.emit("subagent:control-event", { source: "async", event: { type: "needs_attention", runId: "run-b" } });
		assert(h.last() === "⚠ 5 subagents", `attention should show warning, got ${h.last()}`);

		// Answering (a new coordinator turn) acknowledges the attention request
		// while the run keeps working.
		await h.agentStart();
		assert(h.last() === "⚙ 5 subagents", `agent_start should clear attention, got ${h.last()}`);

		h.events.emit("subagent:control-event", { source: "async", event: { type: "needs_attention", runId: "run-b" } });
		assert(h.last() === "⚠ 5 subagents", `a new attention request should show again, got ${h.last()}`);

		h.setActive(1);
		h.events.emit("subagent:async-complete", { runId: "run-b" });
		await sleep(5);
		assert(h.last() === "⚙ 1 subagent", `completion should clear attention and refresh, got ${h.last()}`);

		h.setActive(0);
		h.events.emit("subagent:process-terminal", { runId: "run-a" });
		await sleep(5);
		assert(h.last() === undefined, `no active work should clear the status, got ${h.last()}`);

		// Timer stops once idle: no further requests.
		const before = h.requests;
		await sleep(80);
		assert(h.requests === before, `refresh timer should stop when idle (${h.requests - before} extra requests)`);
		await h.shutdown();
	}

	// A workflow starts before its children: only the wrapper is active at
	// first, and the child appears later without its own start event.
	{
		const h = createHarness();
		await h.start();
		h.setActive(0, 1);
		h.events.emit("subagent:async-started", { id: "wf" });
		await sleep(5);
		assert(h.last() === "⚙ starting", `a workflow with no children yet should show starting, got ${h.last()}`);
		h.setActive(1, 1);
		await sleep(60);
		assert(h.last() === "⚙ 1 subagent", `polling must pick up the child that appears later, got ${h.last()}`);
		h.setActive(0, 0);
		h.events.emit("subagent:async-complete", { runId: "wf" });
		await sleep(5);
		assert(h.last() === undefined, `status should clear when the workflow ends, got ${h.last()}`);
		await h.shutdown();
	}

	// Shutdown clears the status and later events never touch the old session.
	{
		const h = createHarness();
		h.setActive(2);
		let setsAfterShutdown = 0;
		let shutDown = false;
		await h.start(true, () => {
			if (shutDown) setsAfterShutdown++;
		});
		assert(h.last() === "⚙ 2 subagents", "precondition");
		shutDown = true;
		await h.shutdown();
		assert(h.last() === undefined, "shutdown should clear the status item");
		const cleared = setsAfterShutdown;
		const requestsAtShutdown = h.requests;
		h.setActive(4);
		h.events.emit("subagent:async-started", { id: "late" });
		h.events.emit("subagent:control-event", { source: "async", event: { type: "needs_attention", runId: "late" } });
		await sleep(60);
		assert(setsAfterShutdown === cleared, "events after shutdown must not use the old session UI");
		assert(h.requests === requestsAtShutdown, "no status requests after shutdown");
	}

	// Non-interactive sessions (subagent runners) stay silent and never poll.
	{
		const h = createHarness();
		h.setActive(3);
		await h.start(false);
		h.events.emit("subagent:async-started", { id: "x" });
		await sleep(60);
		assert(h.statuses.length === 0, "no status without UI");
		assert(h.requests === 0, "no RPC requests without UI");
	}

	// Missing pi-subagents (no RPC reply) degrades to showing nothing.
	{
		const h = createHarness({ respond: false });
		await h.start();
		assert(h.statuses.length === 0, "no reply should leave the footer untouched");
		await h.shutdown();
	}

	console.log("subagent-status tests passed");
}

main().catch((error) => {
	console.error(`subagent-status test failed: ${error instanceof Error ? error.message : String(error)}`);
	process.exit(1);
});
