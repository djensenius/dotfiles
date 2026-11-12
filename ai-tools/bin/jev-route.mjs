#!/usr/bin/env node
import { realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";

// Initial advisory policy, not calibrated accuracy guarantees.
const POLICY = Object.freeze({
  endpoint: "https://api.typesafe.ai/v1/systemone",
  model: "jev-1.14.0",
  probability: 0.9,
  applicability: 0.9,
  inputBytes: 16 * 1024,
  bodyBytes: 64 * 1024,
  deadlineMs: 10_000,
  sumTolerance: 1e-6,
});
const CRITERIA = Object.freeze({
  scout: "Read-only local reconnaissance to locate relevant code/tests and clarify facts before planning or implementation.",
  planner: "Turn researched requirements into a bounded ordered plan with testable acceptance criteria before implementation.",
  worker: "Implement a bounded authorized change after research and a plan are available.",
  reviewer: "Read-only review of an existing diff/branch against a stated specification and test evidence.",
});
const ROLES = Object.keys(CRITERIA);
const QUESTIONS = {
  route: {
    type: "choice",
    instructions: "Choose the single most appropriate next delegated role for the task summary. Judge only the stated work and available research, plan, or diff.",
    criteria: CRITERIA,
  },
  delegation_useful: {
    type: "noul",
    instructions: "Does this task summary warrant delegating meaningful scoped work to any of these four roles rather than handling a trivial lookup/question directly? Answer no for trivial work or work outside scout (read-only reconnaissance), planner (bounded planning from research), worker (authorized implementation after research/plan), and reviewer (read-only existing-diff review).",
  },
};
const defer = (reason) => ({ agent: null, reason });
const object = (value) => value !== null && typeof value === "object" && !Array.isArray(value);
const unit = (value) => Number.isFinite(value) && value >= 0 && value <= 1;
const count = (value) => Number.isSafeInteger(value) && value >= 0;
const validSummary = (summary) => typeof summary === "string" &&
  summary.trim().length > 0 && Buffer.byteLength(summary, "utf8") <= POLICY.inputBytes;

function validate(value) {
  const route = value?.answers?.route;
  const useful = value?.answers?.delegation_useful;
  const probabilities = route?.probabilities;
  if (!object(value) || value.model !== POLICY.model ||
      route?.type !== "choice" || !ROLES.includes(route.choice) ||
      !unit(route.confidence) || !object(probabilities) ||
      Object.keys(probabilities).length !== ROLES.length ||
      !ROLES.every((role) => Object.hasOwn(probabilities, role) && unit(probabilities[role])) ||
      Math.abs(ROLES.reduce((sum, role) => sum + probabilities[role], 0) - 1) > POLICY.sumTolerance ||
      !ROLES.every((role) => probabilities[role] <= probabilities[route.choice]) ||
      useful?.type !== "noul" || !unit(useful.noul) ||
      !object(value.usage) || !count(value.usage.input_tokens) || !count(value.usage.output_tokens)) {
    return defer("invalid_response");
  }
  const probability = probabilities[route.choice];
  const applicability = useful.noul;
  const warranted = probability >= POLICY.probability && applicability >= POLICY.applicability;
  return {
    agent: warranted ? route.choice : null,
    reason: warranted ? "advisory" : "uncertain",
    probability,
    applicability,
    model: POLICY.model,
    usage: { input_tokens: value.usage.input_tokens, output_tokens: value.usage.output_tokens },
  };
}

// No discovery, retries, execution, payload logging, or configurable endpoint.
// send=true is the caller's explicit declaration that this exact summary is
// owner-approved and non-sensitive; this helper cannot classify secrets safely.
export async function routeSummary(summary, {
  send = false, env = process.env, fetch: fetchImpl = globalThis.fetch, signal,
} = {}) {
  if (!validSummary(summary)) return defer("invalid_input");
  if (!send) return defer("dry_run");
  const key = env.TYPESAFE_API_KEY;
  if (typeof key !== "string" || !key.trim() || key.trim().startsWith("op://") ||
      /[\r\n]/u.test(key)) return defer("credentials_unavailable");

  const controller = new AbortController();
  let reader;
  const cancel = () => {
    // Do not wait indefinitely for an uncooperative stream's cancellation.
    if (reader) void reader.cancel().catch(() => {});
  };
  const abort = () => controller.abort();
  signal?.addEventListener("abort", abort, { once: true });
  if (signal?.aborted) controller.abort();
  controller.signal.addEventListener("abort", cancel, { once: true });
  let timer;
  const interrupted = new Promise((_, reject) => {
    controller.signal.addEventListener("abort", () => reject(new Error("interrupted")), { once: true });
    if (controller.signal.aborted) reject(new Error("interrupted"));
    timer = setTimeout(abort, POLICY.deadlineMs);
  });
  const request = async () => {
    if (controller.signal.aborted) throw new Error("interrupted");
    const response = await fetchImpl(POLICY.endpoint, {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      redirect: "error",
      signal: controller.signal,
      body: JSON.stringify({ model: POLICY.model, state: summary, questions: QUESTIONS }),
    });
    if (!response.ok) {
      if (response.body) void response.body.cancel().catch(() => {});
      return defer("request_failed"); // Never read provider error diagnostics.
    }
    reader = response.body.getReader();
    if (controller.signal.aborted) {
      cancel();
      throw new Error("interrupted");
    }
    const chunks = [];
    let bytes = 0;
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      bytes += value.byteLength;
      if (bytes > POLICY.bodyBytes) return defer("response_too_large");
      chunks.push(value);
    }
    let value;
    try {
      value = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(Buffer.concat(chunks)));
    } catch {
      return defer("invalid_response");
    }
    return validate(value);
  };
  try {
    return await Promise.race([request(), interrupted]);
  } catch {
    return defer(controller.signal.aborted ? "interrupted" : "request_failed");
  } finally {
    clearTimeout(timer);
    signal?.removeEventListener("abort", abort);
    cancel();
  }
}

function parseArgs(args) {
  let mode;
  let summary;
  for (let index = 0; index < args.length; index++) {
    const arg = args[index];
    if (arg === "--send" || arg === "--dry-run") {
      if (mode !== undefined) throw new Error("invalid");
      mode = arg;
    } else if (arg === "--summary") {
      if (summary !== undefined || index + 1 >= args.length ||
          args[index + 1].startsWith("--")) throw new Error("invalid");
      summary = args[++index];
    } else {
      throw new Error("invalid");
    }
  }
  return { send: mode === "--send", summary };
}

async function stdinSummary() {
  const chunks = [];
  let bytes = 0;
  for await (const chunk of process.stdin) {
    bytes += chunk.byteLength;
    if (bytes > POLICY.inputBytes) throw new Error("invalid");
    chunks.push(chunk);
  }
  return new TextDecoder("utf-8", { fatal: true }).decode(Buffer.concat(chunks));
}

async function main() {
  let advice;
  try {
    const args = parseArgs(process.argv.slice(2));
    if (args.summary !== undefined && !process.stdin.isTTY) {
      // Allow empty stdin (e.g. /dev/null), but reject two input sources.
      if ((await stdinSummary()).length > 0) throw new Error("invalid");
    }
    const summary = args.summary ?? await stdinSummary();
    advice = await routeSummary(summary, { send: args.send });
  } catch {
    advice = defer("invalid_input");
  }
  process.stdout.write(`${JSON.stringify(advice)}\n`);
}

// realpath permits invoking the installed symlink, without running on import.
let executable = false;
try {
  executable = process.argv[1] !== undefined &&
    realpathSync(process.argv[1]) === fileURLToPath(import.meta.url);
} catch { /* Importing needs no executable path. */ }
if (executable) await main();
