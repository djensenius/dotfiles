// Shows running subagent work as a footer status item ("⚙ 3 subagents"), so a
// coordinator that reports "idle" is visibly waiting on background work.
//
// Uses only pi-subagents' public in-process surface (docs/extension-api.md):
// lifecycle events plus the event-bus RPC `status` method. Its `data.fleet`
// lists every running child, including workflow children that start and stop
// without top-level events. Workflow runs also appear as their own
// `agent: "workflow"` entry; those are wrappers, not subagents, so they are
// not counted.

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export const STATUS_KEY = "subagents";
const RPC_REQUEST_EVENT = "subagents:rpc:v1:request";
const RPC_REPLY_EVENT_PREFIX = "subagents:rpc:v1:reply:";
const RPC_READY_EVENT = "subagents:rpc:v1:ready";
const ASYNC_STARTED_EVENT = "subagent:async-started";
const ASYNC_COMPLETE_EVENT = "subagent:async-complete";
const PROCESS_TERMINAL_EVENT = "subagent:process-terminal";
const CONTROL_EVENT = "subagent:control-event";

export interface SubagentStatusOptions {
	rpcTimeoutMs?: number;
	refreshMs?: number;
	newRequestId?: () => string;
}

type Unsubscribe = (() => void) | void;

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function formatSubagentStatus(
	active: number,
	needsAttention: boolean,
	busy = active,
	atLeast = false,
): string | undefined {
	const icon = needsAttention ? "⚠" : "⚙";
	// A workflow reports itself before its first child appears.
	if (active <= 0) return busy > 0 ? `${icon} starting` : undefined;
	const noun = active === 1 && !atLeast ? "subagent" : "subagents";
	return `${icon} ${active}${atLeast ? "+" : ""} ${noun}`;
}

function attentionRunId(data: unknown): string | undefined {
	if (!isRecord(data) || data.source !== "async" || !isRecord(data.event)) return undefined;
	const { type, runId } = data.event;
	return type === "needs_attention" && typeof runId === "string" && runId ? runId : undefined;
}

export interface FleetActivity {
	/** Running subagents to display: entries that are not workflow wrappers, plus omitted ones. */
	subagents: number;
	/** Everything active, including workflow wrappers; keeps polling alive until children appear. */
	busy: number;
	/** True when the fleet list was truncated: unclassified entries may be wrappers, so `subagents` is a lower bound. */
	atLeast: boolean;
}

// Running subagents in a fleet DTO. Workflow runs appear as their own
// `agent: "workflow"` entry before and alongside their children.
export function fleetActivity(fleet: unknown): FleetActivity | undefined {
	if (!isRecord(fleet)) return undefined;
	const { entries, omitted, totalActive } = fleet;
	const total = typeof totalActive === "number" && Number.isFinite(totalActive) && totalActive >= 0 ? totalActive : undefined;
	if (Array.isArray(entries)) {
		const subagents = entries.filter((entry) => !(isRecord(entry) && entry.agent === "workflow")).length;
		// Omitted entries are unclassified (subagents or workflow wrappers), so
		// count only visible subagents and mark the result as a lower bound.
		const beyond = typeof omitted === "number" && Number.isFinite(omitted) && omitted > 0 ? omitted : 0;
		return { subagents, busy: Math.max(total ?? 0, entries.length + beyond, subagents), atLeast: beyond > 0 };
	}
	return total === undefined ? undefined : { subagents: total, busy: total, atLeast: false };
}

export function activeSubagentCount(fleet: unknown): number | undefined {
	return fleetActivity(fleet)?.subagents;
}

function completedRunId(data: unknown): string | undefined {
	if (!isRecord(data)) return undefined;
	const id = typeof data.runId === "string" ? data.runId : data.id;
	return typeof id === "string" && id ? id : undefined;
}

export default function subagentStatus(pi: ExtensionAPI, options: SubagentStatusOptions = {}) {
	const rpcTimeoutMs = options.rpcTimeoutMs ?? 2_000;
	const refreshMs = options.refreshMs ?? 5_000;
	const newRequestId = options.newRequestId ?? (() => crypto.randomUUID());

	let ctx: ExtensionContext | undefined;
	let active = 0;
	let busy = 0;
	let atLeast = false;
	let shownText: string | undefined;
	let timer: ReturnType<typeof setInterval> | undefined;
	let refreshing = false;
	let refreshAgain = false;
	const attention = new Set<string>();

	// Only the interactive root session shows status; subagent runner sessions
	// load ambient extensions too but have no UI.
	const live = () => ctx !== undefined && ctx.hasUI === true;

	const render = () => {
		if (!live()) return;
		const text = formatSubagentStatus(active, attention.size > 0, busy, atLeast);
		if (text === shownText) return;
		shownText = text;
		try {
			ctx!.ui.setStatus(STATUS_KEY, text);
		} catch {
			// A replaced or reloaded session invalidates ctx; stop using it.
			stop();
		}
	};

	const syncTimer = () => {
		if (live() && busy > 0 && !timer) {
			timer = setInterval(() => void refresh(), refreshMs);
			(timer as { unref?: () => void }).unref?.();
		} else if ((!live() || busy === 0) && timer) {
			clearInterval(timer);
			timer = undefined;
		}
	};

	const requestActiveCount = () =>
		new Promise<FleetActivity | undefined>((resolve) => {
			const requestId = newRequestId();
			let settled = false;
			let unsubscribe: Unsubscribe;
			const finish = (value: FleetActivity | undefined) => {
				if (settled) return;
				settled = true;
				clearTimeout(timeout);
				if (typeof unsubscribe === "function") unsubscribe();
				resolve(value);
			};
			const timeout = setTimeout(() => finish(undefined), rpcTimeoutMs);
			unsubscribe = pi.events.on(`${RPC_REPLY_EVENT_PREFIX}${requestId}`, (reply: unknown) => {
				finish(
					isRecord(reply) && reply.success === true && isRecord(reply.data)
						? fleetActivity(reply.data.fleet)
						: undefined,
				);
			});
			pi.events.emit(RPC_REQUEST_EVENT, { version: 1, requestId, method: "status", params: {} });
		});

	const refresh = async () => {
		if (!live()) return;
		if (refreshing) {
			refreshAgain = true;
			return;
		}
		refreshing = true;
		try {
			do {
				refreshAgain = false;
				const activity = await requestActiveCount();
				if (!live()) return;
				if (activity !== undefined) {
					active = activity.subagents;
					busy = activity.busy;
					atLeast = activity.atLeast;
					if (busy === 0) attention.clear();
				}
				render();
			} while (refreshAgain);
		} finally {
			refreshing = false;
			syncTimer();
		}
	};

	const stop = () => {
		ctx = undefined;
		if (timer) {
			clearInterval(timer);
			timer = undefined;
		}
	};

	pi.events.on(RPC_READY_EVENT, () => void refresh());
	pi.events.on(ASYNC_STARTED_EVENT, () => void refresh());
	pi.events.on(PROCESS_TERMINAL_EVENT, () => void refresh());
	pi.events.on(ASYNC_COMPLETE_EVENT, (data: unknown) => {
		const id = completedRunId(data);
		if (id) attention.delete(id);
		void refresh();
	});
	pi.events.on(CONTROL_EVENT, (data: unknown) => {
		const id = attentionRunId(data);
		if (!id || !live()) return;
		attention.add(id);
		render();
	});

	// A new coordinator turn means the operator has seen and answered the
	// attention request (pi-subagents' Herdr bridge treats it the same way).
	pi.on("agent_start", async () => {
		if (attention.size === 0) return;
		attention.clear();
		render();
	});

	pi.on("session_start", async (_event, sessionCtx) => {
		stop();
		ctx = sessionCtx;
		active = 0;
		busy = 0;
		atLeast = false;
		shownText = undefined;
		attention.clear();
		await refresh();
	});

	pi.on("session_shutdown", async () => {
		const previous = ctx;
		stop();
		if (previous?.hasUI && shownText !== undefined) {
			try {
				previous.ui.setStatus(STATUS_KEY, undefined);
			} catch {
				// Session already gone.
			}
		}
		shownText = undefined;
	});
}
