import { spawn } from "node:child_process";
import { isAbsolute, win32 } from "node:path";
import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const COMMIT_REF_PATTERN = /^[0-9a-fA-F]{7,40}$/;
const RESOLVED_COMMIT_PATTERN = /^[0-9a-fA-F]{40,64}$/;
const GIT_TIMEOUT_MS = 10_000;
const MAX_STDOUT_BYTES = 48 * 1024;
const MAX_STDERR_BYTES = 8 * 1024;

type ReviewGitOperation = "status" | "show" | "diff" | "log" | "rev-parse";

const ALLOWED_PARAMETER_KEYS: Record<ReviewGitOperation, ReadonlySet<string>> = {
	status: new Set(["operation", "path"]),
	show: new Set(["operation", "commit", "path"]),
	diff: new Set(["operation", "base", "commit", "path"]),
	log: new Set(["operation", "base", "commit", "path"]),
	"rev-parse": new Set(["operation", "commit"]),
};

interface CaptureState {
	chunks: Buffer[];
	capturedBytes: number;
	totalBytes: number;
	truncated: boolean;
}

interface GitResult {
	stdout: string;
	stderr: string;
	stdoutBytes: number;
	stderrBytes: number;
	truncated: boolean;
}

interface ReviewGitDetails {
	operation: ReviewGitOperation;
	repository: string;
	commit?: string;
	base?: string;
	path?: string;
	stdoutBytes: number;
	stderrBytes: number;
	truncated: boolean;
}

function commitRef(description: string) {
	return Type.String({
		description,
		minLength: 7,
		maxLength: 40,
		pattern: "^[0-9a-fA-F]{7,40}$",
	});
}

function optionalPath() {
	return Type.Optional(
		Type.String({
			description:
				"Optional repository-relative literal path. Absolute paths, leading '-', newlines, NUL, and '..' traversal are rejected.",
			minLength: 1,
			maxLength: 4096,
		}),
	);
}

const reviewGitParameters = Type.Union(
	[
		Type.Object(
			{
				operation: Type.Literal("status"),
				path: optionalPath(),
			},
			{ additionalProperties: false },
		),
		Type.Object(
			{
				operation: Type.Literal("show"),
				commit: commitRef("Commit ID or unambiguous prefix to show."),
				path: optionalPath(),
			},
			{ additionalProperties: false },
		),
		Type.Object(
			{
				operation: Type.Literal("diff"),
				base: commitRef("Base commit ID or unambiguous prefix."),
				commit: commitRef("Commit ID or unambiguous prefix to compare against the base."),
				path: optionalPath(),
			},
			{ additionalProperties: false },
		),
		Type.Object(
			{
				operation: Type.Literal("log"),
				commit: commitRef("Commit ID or unambiguous prefix at which to start the log."),
				base: Type.Optional(commitRef("Optional base commit ID or prefix for a base..commit range.")),
				path: optionalPath(),
			},
			{ additionalProperties: false },
		),
		Type.Object(
			{
				operation: Type.Literal("rev-parse"),
				commit: commitRef("Commit ID or unambiguous prefix to resolve."),
			},
			{ additionalProperties: false },
		),
	],
	{
		description:
			"Read-only Git inspection. Each operation accepts only the fields shown in its object schema.",
	},
);

function gitEnvironment(): NodeJS.ProcessEnv {
	const environment = { ...process.env };
	for (const key of Object.keys(environment)) {
		if (key.toUpperCase().startsWith("GIT_")) delete environment[key];
	}

	return {
		...environment,
		GIT_NO_LAZY_FETCH: "1",
		GIT_OPTIONAL_LOCKS: "0",
		GIT_PAGER: "cat",
		GIT_TERMINAL_PROMPT: "0",
		LC_ALL: "C",
		NO_COLOR: "1",
		PAGER: "cat",
	};
}

function appendBounded(state: CaptureState, chunk: Buffer, limit: number): void {
	state.totalBytes += chunk.length;
	const remaining = Math.max(0, limit - state.capturedBytes);
	if (remaining > 0) {
		const captured = chunk.subarray(0, remaining);
		state.chunks.push(captured);
		state.capturedBytes += captured.length;
	}
	if (chunk.length > remaining) state.truncated = true;
}

function capturedText(state: CaptureState): string {
	return Buffer.concat(state.chunks, state.capturedBytes).toString("utf8");
}

async function runGit(
	cwd: string,
	args: readonly string[],
	signal: AbortSignal | undefined,
	description: string,
): Promise<GitResult> {
	if (signal?.aborted) throw new Error(`${description} was cancelled`);

	return await new Promise<GitResult>((resolve, reject) => {
		const stdout: CaptureState = { chunks: [], capturedBytes: 0, totalBytes: 0, truncated: false };
		const stderr: CaptureState = { chunks: [], capturedBytes: 0, totalBytes: 0, truncated: false };
		let aborted = false;
		let settled = false;
		let timedOut = false;

		const child = spawn(
			"git",
			[
				"--no-pager",
				"--no-replace-objects",
				"--literal-pathspecs",
				"-c",
				"color.ui=false",
				"-c",
				"core.fsmonitor=false",
				"-c",
				"core.pager=cat",
				"-c",
				"core.untrackedCache=false",
				"-c",
				"log.showSignature=false",
				"-c",
				"status.submoduleSummary=false",
				"-c",
				"submodule.recurse=false",
				...args,
			],
			{
				cwd,
				env: gitEnvironment(),
				shell: false,
				stdio: ["ignore", "pipe", "pipe"],
				windowsHide: true,
			},
		);

		const timeout = setTimeout(() => {
			timedOut = true;
			child.kill("SIGKILL");
		}, GIT_TIMEOUT_MS);
		timeout.unref();

		const onAbort = () => {
			aborted = true;
			child.kill("SIGKILL");
		};
		signal?.addEventListener("abort", onAbort, { once: true });

		const cleanup = () => {
			clearTimeout(timeout);
			signal?.removeEventListener("abort", onAbort);
		};

		child.stdout.on("data", (chunk: Buffer) => appendBounded(stdout, chunk, MAX_STDOUT_BYTES));
		child.stderr.on("data", (chunk: Buffer) => appendBounded(stderr, chunk, MAX_STDERR_BYTES));

		child.once("error", (error) => {
			if (settled) return;
			settled = true;
			cleanup();
			reject(new Error(`${description} could not start Git: ${error.message}`));
		});

		child.once("close", (code, exitSignal) => {
			if (settled) return;
			settled = true;
			cleanup();

			const stdoutText = capturedText(stdout);
			const stderrText = capturedText(stderr);
			const truncated = stdout.truncated || stderr.truncated;

			if (aborted) {
				reject(new Error(`${description} was cancelled`));
				return;
			}
			if (timedOut) {
				reject(new Error(`${description} timed out after ${GIT_TIMEOUT_MS}ms`));
				return;
			}
			if (code !== 0) {
				const diagnostic = stderrText.trim() || stdoutText.trim() || "Git produced no diagnostic output";
				const exit = code === null ? `signal ${exitSignal ?? "unknown"}` : `exit ${code}`;
				reject(new Error(`${description} failed (${exit}): ${diagnostic}`));
				return;
			}

			resolve({
				stdout: stdoutText,
				stderr: stderrText,
				stdoutBytes: stdout.totalBytes,
				stderrBytes: stderr.totalBytes,
				truncated,
			});
		});
	});
}

async function repositoryRoot(cwd: string, signal: AbortSignal | undefined): Promise<string> {
	let result: GitResult;
	try {
		result = await runGit(cwd, ["rev-parse", "--show-toplevel"], signal, "Git repository discovery");
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		throw new Error(`Current working directory is not inside an accessible Git worktree: ${message}`);
	}

	const root = result.stdout.trim();
	if (!root || !isAbsolute(root) || root.includes("\0") || /[\r\n]/.test(root)) {
		throw new Error("Git returned an invalid repository top-level path");
	}
	return root;
}

function requireCommitRef(value: unknown, name: "commit" | "base"): string {
	if (typeof value !== "string" || !COMMIT_REF_PATTERN.test(value)) {
		throw new Error(`${name} must be a 7-40 character hexadecimal commit ID or prefix`);
	}
	return value;
}

async function resolveCommit(
	repository: string,
	value: unknown,
	name: "commit" | "base",
	signal: AbortSignal | undefined,
): Promise<string> {
	const reference = requireCommitRef(value, name);
	let result: GitResult;
	try {
		result = await runGit(
			repository,
			["rev-parse", "--verify", "--quiet", `${reference}^{commit}`],
			signal,
			`Resolve ${name}`,
		);
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		throw new Error(`${name} ${reference} does not resolve to a commit in this repository: ${message}`);
	}

	const resolved = result.stdout.trim();
	if (!RESOLVED_COMMIT_PATTERN.test(resolved)) {
		throw new Error(`Git returned an invalid object ID while resolving ${name}`);
	}
	return resolved.toLowerCase();
}

function repositoryPath(value: unknown): string | undefined {
	if (value === undefined) return undefined;
	if (typeof value !== "string" || value.length === 0) {
		throw new Error("path must be a non-empty repository-relative path");
	}
	if (value.length > 4096) throw new Error("path must be at most 4096 characters");
	if (value.startsWith("-")) throw new Error("path must not begin with '-'");
	if (value.includes("\0") || /[\r\n]/.test(value)) {
		throw new Error("path must not contain NUL or newline characters");
	}
	if (isAbsolute(value) || win32.isAbsolute(value) || /^[A-Za-z]:/.test(value)) {
		throw new Error("path must be repository-relative");
	}
	if (value.split(/[\\/]/).includes("..")) {
		throw new Error("path must not contain '..' traversal");
	}
	return value;
}

function validateParameters(params: Record<string, unknown>): ReviewGitOperation {
	const operation = params.operation;
	if (
		operation !== "status"
		&& operation !== "show"
		&& operation !== "diff"
		&& operation !== "log"
		&& operation !== "rev-parse"
	) {
		throw new Error(`Unsupported read-only Git operation: ${String(operation)}`);
	}

	const allowedKeys = ALLOWED_PARAMETER_KEYS[operation];
	for (const key of Object.keys(params)) {
		if (!allowedKeys.has(key)) throw new Error(`${key} is not valid for ${operation}`);
	}
	return operation;
}

function formatResult(
	result: GitResult,
	details: Omit<ReviewGitDetails, "stdoutBytes" | "stderrBytes" | "truncated">,
	emptyMessage: string,
): { content: Array<{ type: "text"; text: string }>; details: ReviewGitDetails } {
	const lines = [`Repository: ${details.repository}`, `Operation: ${details.operation}`];
	if (details.base) lines.push(`Base: ${details.base}`);
	if (details.commit) lines.push(`Commit: ${details.commit}`);
	if (details.path) lines.push(`Path: ${details.path}`);

	lines.push("", result.stdout.trimEnd() || emptyMessage);
	if (result.stderr.trim()) lines.push("", "[git stderr]", result.stderr.trimEnd());
	if (result.truncated) {
		lines.push(
			"",
			`[Output truncated to ${MAX_STDOUT_BYTES} stdout bytes and ${MAX_STDERR_BYTES} stderr bytes.]`,
		);
	}

	return {
		content: [{ type: "text", text: lines.join("\n") }],
		details: {
			...details,
			stdoutBytes: result.stdoutBytes,
			stderrBytes: result.stderrBytes,
			truncated: result.truncated,
		},
	};
}

export const reviewGitTool = defineTool({
	name: "review_git",
	label: "Review Git",
	description:
		"Read-only inspection of the Git worktree containing the current directory. Fixed operations only: status; show(commit); diff(base, commit); log(commit, optional base); rev-parse(commit). Commit refs must be 7-40 hexadecimal characters. Optional paths are validated repository-relative literals. No command, argv, repository, environment, or flags can be supplied.",
	parameters: reviewGitParameters,

	async execute(_toolCallId, params, signal, _onUpdate, ctx) {
		const rawParams = params as Record<string, unknown>;
		const operation = validateParameters(rawParams);
		const repository = await repositoryRoot(ctx.cwd, signal);
		const path = repositoryPath(rawParams.path);

		switch (operation) {
			case "status": {
				const result = await runGit(
					repository,
					["status", "--porcelain=v1", "--branch", "--untracked-files=all", "--ignore-submodules=all", "--", ...(path ? [path] : [])],
					signal,
					"git status",
				);
				return formatResult(
					result,
					{ operation, repository, ...(path ? { path } : {}) },
					"Working tree clean",
				);
			}
			case "show": {
				const commit = await resolveCommit(repository, rawParams.commit, "commit", signal);
				const result = await runGit(
					repository,
					[
						"show",
						"--no-color",
						"--no-ext-diff",
						"--no-textconv",
						"--ignore-submodules=all",
						"--format=fuller",
						"--stat",
						"--patch",
						commit,
						"--",
						...(path ? [path] : []),
					],
					signal,
					"git show",
				);
				return formatResult(
					result,
					{ operation, repository, commit, ...(path ? { path } : {}) },
					"Commit produced no output",
				);
			}
			case "diff": {
				const base = await resolveCommit(repository, rawParams.base, "base", signal);
				const commit = await resolveCommit(repository, rawParams.commit, "commit", signal);
				const result = await runGit(
					repository,
					[
						"diff",
						"--no-color",
						"--no-ext-diff",
						"--no-textconv",
						"--ignore-submodules=all",
						"--stat",
						"--patch",
						base,
						commit,
						"--",
						...(path ? [path] : []),
					],
					signal,
					"git diff",
				);
				return formatResult(
					result,
					{ operation, repository, base, commit, ...(path ? { path } : {}) },
					"No differences",
				);
			}
			case "log": {
				const commit = await resolveCommit(repository, rawParams.commit, "commit", signal);
				const base = rawParams.base === undefined
					? undefined
					: await resolveCommit(repository, rawParams.base, "base", signal);
				const revision = base ? `${base}..${commit}` : commit;
				const result = await runGit(
					repository,
					[
						"log",
						"--no-color",
						"--no-decorate",
						"--no-ext-diff",
						"--no-textconv",
						"--ignore-submodules=all",
						"--date=iso-strict",
						"--max-count=20",
						"--format=format:%H %ad %an <%ae>%n    %s",
						revision,
						"--",
						...(path ? [path] : []),
					],
					signal,
					"git log",
				);
				return formatResult(
					result,
					{ operation, repository, commit, ...(base ? { base } : {}), ...(path ? { path } : {}) },
					"No commits",
				);
			}
			case "rev-parse": {
				const commit = await resolveCommit(repository, rawParams.commit, "commit", signal);
				const result: GitResult = {
					stdout: commit,
					stderr: "",
					stdoutBytes: Buffer.byteLength(commit),
					stderrBytes: 0,
					truncated: false,
				};
				return formatResult(result, { operation, repository, commit }, "Commit did not resolve");
			}
		}
	},
});

export default function reviewerGitExtension(pi: ExtensionAPI) {
	pi.registerTool(reviewGitTool);
}
