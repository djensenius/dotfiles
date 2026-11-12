import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { test } from "node:test";
import { routeSummary } from "../bin/jev-route.mjs";

const summary = "Review an existing synthetic change against its public specification.";
const env = { TYPESAFE_API_KEY: "synthetic-test-key" };
const roles = ["scout", "planner", "worker", "reviewer"];
function answer(role = "reviewer", probability = 0.97, noul = 0.96) {
  return {
    model: "jev-1.14.0",
    answers: {
      route: {
        type: "choice", choice: role, confidence: 0.5,
        probabilities: Object.fromEntries(roles.map((name) =>
          [name, name === role ? probability : (1 - probability) / 3])),
      },
      delegation_useful: { type: "noul", noul },
    },
    usage: { input_tokens: 42, output_tokens: 0 },
  };
}
const response = (value) => new Response(JSON.stringify(value));
const invoke = (value, options = {}) => routeSummary(summary, {
  send: true, env, fetch: async () => response(value), ...options,
});
const fallback = (result, reason) => assert.deepEqual(result, { agent: null, reason });

test("opt-in and credentials gates perform zero fetches", async () => {
  let calls = 0;
  const fetch = () => { calls++; throw new Error("must not fetch"); };
  fallback(await routeSummary(summary, { env, fetch }), "dry_run");
  fallback(await routeSummary(summary, { send: false, env, fetch }), "dry_run");
  for (const key of [undefined, "", "  ", "op://approved/reference", " op://reference ", "bad\nkey"]) {
    fallback(await routeSummary(summary, {
      send: true, env: { TYPESAFE_API_KEY: key }, fetch,
    }), "credentials_unavailable");
  }
  for (const input of ["", " ", "🌱".repeat(4097), null]) {
    fallback(await routeSummary(input, { send: true, env, fetch }), "invalid_input");
  }
  assert.equal(calls, 0);
});

test("one pinned HTTPS batched request and all four advisory roles", async () => {
  let calls = 0;
  const result = await routeSummary(summary, { send: true, env, fetch: async (url, init) => {
    calls++;
    assert.equal(url, "https://api.typesafe.ai/v1/systemone");
    assert.equal(init.method, "POST");
    assert.equal(init.redirect, "error");
    assert.deepEqual(init.headers, {
      Authorization: "Bearer synthetic-test-key", "Content-Type": "application/json",
    });
    assert.ok(init.signal instanceof AbortSignal);
    assert.deepEqual(JSON.parse(init.body), {
      model: "jev-1.14.0", state: summary,
      questions: {
        route: {
          type: "choice",
          instructions: "Choose the single most appropriate next delegated role for the task summary. Judge only the stated work and available research, plan, or diff.",
          criteria: {
            scout: "Read-only local reconnaissance to locate relevant code/tests and clarify facts before planning or implementation.",
            planner: "Turn researched requirements into a bounded ordered plan with testable acceptance criteria before implementation.",
            worker: "Implement a bounded authorized change after research and a plan are available.",
            reviewer: "Read-only review of an existing diff/branch against a stated specification and test evidence.",
          },
        },
        delegation_useful: {
          type: "noul",
          instructions: "Does this task summary warrant delegating meaningful scoped work to any of these four roles rather than handling a trivial lookup/question directly? Answer no for trivial work or work outside scout (read-only reconnaissance), planner (bounded planning from research), worker (authorized implementation after research/plan), and reviewer (read-only existing-diff review).",
        },
      },
    });
    return response(answer());
  } });
  assert.equal(calls, 1);
  assert.equal(result.agent, "reviewer");
  for (const role of roles) {
    assert.deepEqual(await invoke(answer(role)), {
      agent: role, reason: "advisory", probability: 0.97, applicability: 0.96,
      model: "jev-1.14.0", usage: { input_tokens: 42, output_tokens: 0 },
    });
  }
});

test("companion Noul and selected probability must both meet policy, not confidence", async () => {
  for (const noul of [0, 0.5, 0.899]) {
    const value = answer("worker", 0.99, noul);
    value.answers.route.confidence = 1;
    const result = await invoke(value);
    assert.equal(result.agent, null);
    assert.equal(result.reason, "uncertain");
    assert.equal(result.applicability, noul);
  }
  assert.equal((await invoke(answer("worker", 0.899, 1))).agent, null);
  const boundary = answer("worker", 0.9, 0.9);
  boundary.answers.route.confidence = 0;
  assert.equal((await invoke(boundary)).agent, "worker");
});

test("invalid contracts fall back atomically without trusting partial fields", async () => {
  const mutations = [
    (v) => { v.model = "unknown"; },
    (v) => { v.answers.route.choice = "shell"; },
    (v) => { v.answers.route.type = "noul"; },
    (v) => { v.answers.delegation_useful.type = "choice"; },
    (v) => { v.answers.route.confidence = "0.99"; },
    (v) => { v.answers.route.confidence = 2; },
    (v) => { v.answers.route.confidence = NaN; },
    (v) => { v.answers.delegation_useful.noul = Infinity; },
    (v) => { v.answers.delegation_useful.noul = -1; },
    (v) => { v.answers.route.probabilities.scout = "0.01"; },
    (v) => { v.answers.route.probabilities.scout = Infinity; },
    (v) => { v.answers.route.probabilities.scout = -0.1; },
    (v) => { v.answers.route.probabilities.scout = 1.1; },
    (v) => { delete v.answers.route.probabilities.scout; },
    (v) => { v.answers.route.probabilities.extra = 0; },
    (v) => { v.answers.route.probabilities.scout = 0.3; },
    (v) => { v.answers.route.choice = "scout"; },
    (v) => { v.usage.input_tokens = -1; },
    (v) => { v.usage.output_tokens = 0.5; },
    (v) => { v.usage.input_tokens = "42"; },
    (v) => { delete v.usage; },
    (v) => { delete v.answers; },
  ];
  for (const mutate of mutations) {
    const value = answer();
    mutate(value);
    fallback(await invoke(value), "invalid_response");
  }
  for (const value of [null, [], "synthetic"]) {
    fallback(await invoke(value), "invalid_response");
  }
  fallback(await routeSummary(summary, {
    send: true, env, fetch: async () => new Response("{broken"),
  }), "invalid_response");
});

test("provider errors are unread, bounded streams cancel, and entire request times out", async (t) => {
  let reads = 0;
  let cancellations = 0;
  let calls = 0;
  fallback(await routeSummary(summary, { send: true, env, fetch: async () => {
    calls++;
    return {
      ok: false,
      body: {
        getReader() { reads++; throw new Error(`${summary} ${env.TYPESAFE_API_KEY}`); },
        async cancel() { cancellations++; },
      },
    };
  } }), "request_failed");
  assert.equal(reads, 0);
  assert.equal(calls, 1);
  assert.equal(cancellations, 1);
  fallback(await routeSummary(summary, { send: true, env, fetch: async () => {
    throw new Error(`${summary} ${env.TYPESAFE_API_KEY}`);
  } }), "request_failed");
  fallback(await routeSummary(summary, { send: true, env, fetch: async () => ({
    ok: true,
    body: new ReadableStream({
      start(controller) { controller.enqueue(new Uint8Array(65537)); },
      cancel() { cancellations++; },
    }),
  }) }), "response_too_large");
  assert.equal(cancellations, 2);

  t.mock.timers.enable({ apis: ["setTimeout"] });
  let requestSignal;
  const stalledFetch = routeSummary(summary, { send: true, env, fetch: async (_, init) => {
    requestSignal = init.signal;
    return await new Promise(() => {});
  } });
  t.mock.timers.tick(10_000);
  fallback(await stalledFetch, "interrupted");
  assert.equal(requestSignal.aborted, true);

  const stalledBody = routeSummary(summary, { send: true, env, fetch: async () => ({
    ok: true,
    body: new ReadableStream({
      start(controller) { controller.enqueue(new TextEncoder().encode('{"model":')); },
      cancel() { cancellations++; },
    }),
  }) });
  // Let fetch resolve and the body reader start before advancing the deadline.
  await Promise.resolve();
  await Promise.resolve();
  t.mock.timers.tick(10_000);
  fallback(await stalledBody, "interrupted");
  assert.equal(cancellations, 3);
});

test("CLI text/stdin are dry by default, malformed inputs are generic, import is safe", () => {
  const helper = new URL("../bin/jev-route.mjs", import.meta.url);
  const cli = (args, input = "") => {
    const result = spawnSync(process.execPath, [helper.pathname, ...args], {
      input, encoding: "utf8", env: { PATH: process.env.PATH }, timeout: 2000,
    });
    assert.equal(result.status, 0);
    assert.equal(result.stderr, "");
    return JSON.parse(result.stdout);
  };
  fallback(cli(["--summary", summary]), "dry_run");
  fallback(cli(["--dry-run"], summary), "dry_run");
  fallback(cli([], summary), "dry_run");
  fallback(cli(["--send", "--summary", summary]), "credentials_unavailable");
  for (const args of [
    ["--send", "--dry-run"], ["--send", "--send"], ["--summary"],
    ["--summary", summary, "--summary", summary], ["--key", "synthetic-test-key"],
    ["--summary", "🌱".repeat(4097)],
  ]) fallback(cli(args), "invalid_input");
  fallback(cli([], "🌱".repeat(4097)), "invalid_input");
  fallback(cli(["--summary", summary], summary), "invalid_input");
  const imported = spawnSync(process.execPath, ["--input-type=module", "-e",
    `globalThis.fetch = () => { throw new Error("unexpected fetch"); }; await import(${JSON.stringify(helper.href)});`,
  ], { encoding: "utf8", timeout: 2000 });
  assert.equal(imported.status, 0);
  assert.equal(imported.stdout, "");
  assert.equal(imported.stderr, "");
});
