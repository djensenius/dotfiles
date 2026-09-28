import { spawn } from "node:child_process";
import { isAbsolute, win32 } from "node:path";
import { StringDecoder } from "node:string_decoder";
import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const COMMIT_ID_PATTERN = /^[0-9a-fA-F]{40}$/;
const DEFAULT_PAGE_SIZE = 12_000;
const GIT_TIMEOUT_MS = 10_000;
const MAX_CONTROL_STDOUT_BYTES = 8 * 1024;
const MAX_PAGE = 1_000_000;
const MAX_PAGE_SIZE = 16_384;
const MAX_STDERR_BYTES = 8 * 1024;
const UTF8_REPLACEMENT_NOTE =
	"Git stdout is decoded as UTF-8. Invalid or incomplete byte sequences become U+FFFD; valid UTF-8 characters are never split between pages.";

type ReviewGitOperation = "show" | "diff" | "log" | "rev-parse";

const ALLOWED_PARAMETER_KEYS: Record<ReviewGitOperation, ReadonlySet<string>> = {
	show: new Set(["operation", "commit", "path", "page", "pageSize"]),
	diff: new Set(["operation", "base", "commit", "path", "page", "pageSize"]),
	log: new Set(["operation", "base", "commit", "path", "page", "pageSize"]),
	"rev-parse": new Set(["operation", "commit"]),
};

interface BoundedCaptureState {
	chunks: Buffer[];
	capturedBytes: number;
	totalBytes: number;
	truncated: boolean;
}

interface PageRequest {
	page: number;
	pageSize: number;
}

interface PaginationDetails extends PageRequest {
	pageCodePoints: number;
	pageUtf8Bytes: number;
	startCodePoint: number;
	endCodePointExclusive: number;
	totalCodePoints: number;
	totalPages: number;
	hasNextPage: boolean;
	nextPage?: number;
}

interface PageCaptureState {
	decoder: StringDecoder;
	chunks: string[];
	pageStart: number;
	pageEnd: number;
	pageCodePoints: number;
	pageUtf8Bytes: number;
	totalBytes: number;
	totalCodePoints: number;
}

interface GitResult {
	stdout: string;
	stderr: string;
	stdoutBytes: number;
	stderrBytes: number;
	pagination?: PaginationDetails;
}

interface ReviewGitDetails {
	operation: ReviewGitOperation;
	repository: string;
	commit?: string;
	base?: string;
	path?: string;
	stdoutBytes: number;
	stderrBytes: number;
	pagination?: PaginationDetails;
}

function commitId(description: string) {
	return Type.String({
		description,
		minLength: 40,
		maxLength: 40,
		pattern: "^[0-9a-fA-F]{40}$",
	});
}

function pageNumber() {
	return Type.Optional(
		Type.Integer({
			description: "One-based output page. Defaults to 1.",
			minimum: 1,
			maximum: MAX_PAGE,
			default: 1,
		}),
	);
}

function pageSize() {
	return Type.Optional(
		Type.Integer({
			description: `Maximum decoded Unicode code points in this page. Defaults to ${DEFAULT_PAGE_SIZE}; maximum ${MAX_PAGE_SIZE}.`,
			minimum: 1,
			maximum: MAX_PAGE_SIZE,
			default: DEFAULT_PAGE_SIZE,
		}),
	);
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
				operation: Type.Literal("show"),
				commit: commitId("Full 40-character hexadecimal commit ID to show."),
				path: optionalPath(),
				page: pageNumber(),
				pageSize: pageSize(),
			},
			{ additionalProperties: false },
		),
		Type.Object(
			{
				operation: Type.Literal("diff"),
				base: commitId("Full 40-character hexadecimal base commit ID."),
				commit: commitId("Full 40-character hexadecimal commit ID to compare against the base."),
				path: optionalPath(),
				page: pageNumber(),
				pageSize: pageSize(),
			},
			{ additionalProperties: false },
		),
		Type.Object(
			{
				operation: Type.Literal("log"),
				commit: commitId("Full 40-character hexadecimal commit ID at which to start the log."),
				base: Type.Optional(commitId("Optional full 40-character hexadecimal base commit ID.")),
				path: optionalPath(),
				page: pageNumber(),
				pageSize: pageSize(),
			},
			{ additionalProperties: false },
		),
		Type.Object(
			{
				operation: Type.Literal("rev-parse"),
				commit: commitId("Full 40-character hexadecimal commit ID to verify and resolve."),
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
		GIT_CONFIG_NOSYSTEM: "1",
		GIT_NO_LAZY_FETCH: "1",
		GIT_OPTIONAL_LOCKS: "0",
		GIT_PAGER: "cat",
		GIT_TERMINAL_PROMPT: "0",
		LC_ALL: "C",
		NO_COLOR: "1",
		PAGER: "cat",
	};
}

function appendBounded(state: BoundedCaptureState, chunk: Buffer, limit: number): void {
	state.totalBytes += chunk.length;
	const remaining = Math.max(0, limit - state.capturedBytes);
	if (remaining > 0) {
		const captured = chunk.subarray(0, remaining);
		state.chunks.push(captured);
		state.capturedBytes += captured.length;
	}
	if (chunk.length > remaining) state.truncated = true;
}

function capturedText(state: BoundedCaptureState): string {
	return Buffer.concat(state.chunks, state.capturedBytes).toString("utf8");
}

function appendDecodedPage(state: PageCaptureState, text: string): void {
	const captured: string[] = [];
	for (const character of text) {
		const index = state.totalCodePoints;
		state.totalCodePoints += 1;
		if (index < state.pageStart || index >= state.pageEnd) continue;
		captured.push(character);
		state.pageCodePoints += 1;
	}
	if (captured.length === 0) return;

	const chunk = captured.join("");
	state.chunks.push(chunk);
	state.pageUtf8Bytes += Buffer.byteLength(chunk);
}

async function runGit(
	cwd: string,
	args: readonly string[],
	signal: AbortSignal | undefined,
	description: string,
	pageRequest?: PageRequest,
): Promise<GitResult> {
	if (signal?.aborted) throw new Error(`${description} was cancelled`);

	return await new Promise<GitResult>((resolve, reject) => {
		const stdout: BoundedCaptureState = { chunks: [], capturedBytes: 0, totalBytes: 0, truncated: false };
		const stderr: BoundedCaptureState = { chunks: [], capturedBytes: 0, totalBytes: 0, truncated: false };
		const paginatedStdout: PageCaptureState | undefined = pageRequest
			? {
					decoder: new StringDecoder("utf8"),
					chunks: [],
					pageStart: (pageRequest.page - 1) * pageRequest.pageSize,
					pageEnd: pageRequest.page * pageRequest.pageSize,
					pageCodePoints: 0,
					pageUtf8Bytes: 0,
					totalBytes: 0,
					totalCodePoints: 0,
				}
			: undefined;
		let aborted = false;
		let settled = false;
		let stderrOverflow = false;
		let stdoutOverflow = false;
		let timedOut = false;

		const child = spawn(
			"git",
			[
				"--no-pager",
				"--no-lazy-fetch",
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

		child.stdout.on("data", (chunk: Buffer) => {
			if (paginatedStdout) {
				paginatedStdout.totalBytes += chunk.length;
				appendDecodedPage(paginatedStdout, paginatedStdout.decoder.write(chunk));
				return;
			}

			appendBounded(stdout, chunk, MAX_CONTROL_STDOUT_BYTES);
			if (stdout.truncated && !stdoutOverflow) {
				stdoutOverflow = true;
				child.kill("SIGKILL");
			}
		});
		child.stderr.on("data", (chunk: Buffer) => {
			appendBounded(stderr, chunk, MAX_STDERR_BYTES);
			if (stderr.truncated && !stderrOverflow) {
				stderrOverflow = true;
				child.kill("SIGKILL");
			}
		});

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

			const stderrText = capturedText(stderr);

			if (aborted) {
				reject(new Error(`${description} was cancelled`));
				return;
			}
			if (timedOut) {
				reject(new Error(`${description} timed out after ${GIT_TIMEOUT_MS}ms`));
				return;
			}
			if (stderrOverflow) {
				const diagnostic = stderrText.trim();
				reject(
					new Error(
						`${description} failed because Git diagnostics exceeded ${MAX_STDERR_BYTES} bytes and were truncated${diagnostic ? `: ${diagnostic}` : ""}`,
					),
				);
				return;
			}
			if (stdoutOverflow) {
				reject(
					new Error(
						`${description} failed because control output exceeded ${MAX_CONTROL_STDOUT_BYTES} bytes`,
					),
				);
				return;
			}

			const stdoutText = paginatedStdout
				? (() => {
						appendDecodedPage(paginatedStdout, paginatedStdout.decoder.end());
						return paginatedStdout.chunks.join("");
					})()
				: capturedText(stdout);

			if (code !== 0) {
				const diagnostic = stderrText.trim() || stdoutText.trim() || "Git produced no diagnostic output";
				const exit = code === null ? `signal ${exitSignal ?? "unknown"}` : `exit ${code}`;
				reject(new Error(`${description} failed (${exit}): ${diagnostic}`));
				return;
			}

			if (paginatedStdout && pageRequest) {
				const totalPages = Math.max(1, Math.ceil(paginatedStdout.totalCodePoints / pageRequest.pageSize));
				if (pageRequest.page > totalPages) {
					reject(
						new Error(
							`${description} page ${pageRequest.page} is out of range; output has ${totalPages} page${totalPages === 1 ? "" : "s"} at pageSize ${pageRequest.pageSize}`,
						),
					);
					return;
				}

				const pagination: PaginationDetails = {
					...pageRequest,
					pageCodePoints: paginatedStdout.pageCodePoints,
					pageUtf8Bytes: paginatedStdout.pageUtf8Bytes,
					startCodePoint: paginatedStdout.pageStart,
					endCodePointExclusive: Math.min(paginatedStdout.pageEnd, paginatedStdout.totalCodePoints),
					totalCodePoints: paginatedStdout.totalCodePoints,
					totalPages,
					hasNextPage: pageRequest.page < totalPages,
					...(pageRequest.page < totalPages ? { nextPage: pageRequest.page + 1 } : {}),
				};
				resolve({
					stdout: stdoutText,
					stderr: stderrText,
					stdoutBytes: paginatedStdout.totalBytes,
					stderrBytes: stderr.totalBytes,
					pagination,
				});
				return;
			}

			resolve({
				stdout: stdoutText,
				stderr: stderrText,
				stdoutBytes: stdout.totalBytes,
				stderrBytes: stderr.totalBytes,
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

	const root = result.stdout.replace(/\n$/, "");
	if (!root || !isAbsolute(root) || root.includes("\0") || /[\r\n]/.test(root)) {
		throw new Error("Git returned an invalid repository top-level path");
	}
	return root;
}

function requireCommitId(value: unknown, name: "commit" | "base"): string {
	if (typeof value !== "string" || !COMMIT_ID_PATTERN.test(value)) {
		throw new Error(`${name} must be exactly 40 hexadecimal characters`);
	}
	return value;
}

function boundedInteger(
	value: unknown,
	name: "page" | "pageSize",
	defaultValue: number,
	maximum: number,
): number {
	if (value === undefined) return defaultValue;
	if (typeof value !== "number" || !Number.isInteger(value) || value < 1 || value > maximum) {
		throw new Error(`${name} must be an integer between 1 and ${maximum}`);
	}
	return value;
}

function paginationRequest(
	params: Record<string, unknown>,
	operation: ReviewGitOperation,
): PageRequest | undefined {
	if (operation === "rev-parse") return undefined;
	return {
		page: boundedInteger(params.page, "page", 1, MAX_PAGE),
		pageSize: boundedInteger(params.pageSize, "pageSize", DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE),
	};
}

async function resolveCommit(
	repository: string,
	reference: string,
	name: "commit" | "base",
	signal: AbortSignal | undefined,
): Promise<string> {
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
	if (!COMMIT_ID_PATTERN.test(resolved)) {
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
		operation !== "show"
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
	details: Omit<ReviewGitDetails, "stdoutBytes" | "stderrBytes" | "pagination">,
	emptyMessage: string,
): { content: Array<{ type: "text"; text: string }>; details: ReviewGitDetails } {
	const lines = [`Repository: ${details.repository}`, `Operation: ${details.operation}`];
	if (details.base) lines.push(`Base: ${details.base}`);
	if (details.commit) lines.push(`Commit: ${details.commit}`);
	if (details.path) lines.push(`Path: ${details.path}`);

	if (result.pagination) {
		const page = result.pagination;
		lines.push(
			`Page: ${page.page}/${page.totalPages}`,
			`Page size: ${page.pageSize} Unicode code points`,
			`Window: [${page.startCodePoint}, ${page.endCodePointExclusive}) of ${page.totalCodePoints} code points`,
			`Has next page: ${page.hasNextPage ? "yes" : "no"}`,
			...(page.nextPage ? [`Next page: ${page.nextPage}`] : []),
			UTF8_REPLACEMENT_NOTE,
		);
	}
	if (!result.stdout) lines.push(`Result: ${emptyMessage}`);
	lines.push("Git stdout is returned in the next text block.");

	const content: Array<{ type: "text"; text: string }> = [
		{ type: "text", text: lines.join("\n") },
		{ type: "text", text: result.stdout },
	];
	if (result.stderr.trim()) {
		content.push({ type: "text", text: `[git stderr]\n${result.stderr.trimEnd()}` });
	}

	return {
		content,
		details: {
			...details,
			stdoutBytes: result.stdoutBytes,
			stderrBytes: result.stderrBytes,
			...(result.pagination ? { pagination: result.pagination } : {}),
		},
	};
}

export const reviewGitTool = defineTool({
	name: "review_git",
	label: "Review Git",
	description:
		`Read-only inspection of committed Git objects in the worktree containing the current directory. Fixed operations only: show(commit); diff(base, commit); log(commit, optional base); rev-parse(commit). Commit IDs must be exactly 40 hexadecimal characters. show, diff, and log use one-based page/pageSize pagination with a default page size of ${DEFAULT_PAGE_SIZE} and maximum ${MAX_PAGE_SIZE} Unicode code points. ${UTF8_REPLACEMENT_NOTE} Optional paths are validated repository-relative literals. No command, argv, repository, environment, or flags can be supplied.`,
	parameters: reviewGitParameters,

	async execute(_toolCallId, params, signal, _onUpdate, ctx) {
		const rawParams = params as Record<string, unknown>;
		const operation = validateParameters(rawParams);
		const path = repositoryPath(rawParams.path);
		const page = paginationRequest(rawParams, operation);
		const commitInput = requireCommitId(rawParams.commit, "commit");
		const baseInput = operation === "diff"
			? requireCommitId(rawParams.base, "base")
			: operation === "log" && rawParams.base !== undefined
				? requireCommitId(rawParams.base, "base")
				: undefined;
		const repository = await repositoryRoot(ctx.cwd, signal);

		switch (operation) {
			case "show": {
				const commit = await resolveCommit(repository, commitInput, "commit", signal);
				const result = await runGit(
					repository,
					[
						"show",
						"--no-color",
						"--no-ext-diff",
						"--no-textconv",
						"--text",
						"--ignore-submodules=dirty",
						"--submodule=short",
						"--format=fuller",
						"--stat",
						"--patch",
						commit,
						"--",
						...(path ? [path] : []),
					],
					signal,
					"git show",
					page,
				);
				return formatResult(
					result,
					{ operation, repository, commit, ...(path ? { path } : {}) },
					"Commit produced no output",
				);
			}
			case "diff": {
				const base = await resolveCommit(repository, baseInput!, "base", signal);
				const commit = await resolveCommit(repository, commitInput, "commit", signal);
				const result = await runGit(
					repository,
					[
						"diff",
						"--no-color",
						"--no-ext-diff",
						"--no-textconv",
						"--text",
						"--ignore-submodules=dirty",
						"--submodule=short",
						"--stat",
						"--patch",
						base,
						commit,
						"--",
						...(path ? [path] : []),
					],
					signal,
					"git diff",
					page,
				);
				return formatResult(
					result,
					{ operation, repository, base, commit, ...(path ? { path } : {}) },
					"No differences",
				);
			}
			case "log": {
				const commit = await resolveCommit(repository, commitInput, "commit", signal);
				const base = baseInput === undefined
					? undefined
					: await resolveCommit(repository, baseInput, "base", signal);
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
					page,
				);
				return formatResult(
					result,
					{ operation, repository, commit, ...(base ? { base } : {}), ...(path ? { path } : {}) },
					"No commits",
				);
			}
			case "rev-parse": {
				const commit = await resolveCommit(repository, commitInput, "commit", signal);
				const result: GitResult = {
					stdout: commit,
					stderr: "",
					stdoutBytes: Buffer.byteLength(commit),
					stderrBytes: 0,
				};
				return formatResult(result, { operation, repository, commit }, "Commit did not resolve");
			}
		}
	},
});

export default function reviewerGitExtension(pi: ExtensionAPI) {
	pi.registerTool(reviewGitTool);
}
