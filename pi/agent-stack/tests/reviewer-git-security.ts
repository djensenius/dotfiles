import { readFile, realpath, stat } from "node:fs/promises";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { reviewGitTool } from "../extensions/reviewer-git.ts";

const EXPECTED_OPERATIONS = ["diff", "log", "rev-parse", "show"];
const PAGE_SIZE = 4_097;

function assert(condition: unknown, message: string): asserts condition {
	if (!condition) throw new Error(message);
}

function errorMessage(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}

async function rejection(run: () => Promise<unknown>): Promise<string> {
	try {
		await run();
	} catch (error) {
		return errorMessage(error);
	}
	throw new Error("expected operation to be rejected");
}

function requiredEnvironment(name: string): string {
	const value = process.env[name];
	assert(value, `${name} is required`);
	return value;
}

async function fileSize(path: string): Promise<number> {
	try {
		return (await stat(path)).size;
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") return 0;
		throw error;
	}
}

async function withGitMode<T>(mode: string, run: () => Promise<T>): Promise<T> {
	const previous = process.env.REVIEW_GIT_TEST_MODE;
	process.env.REVIEW_GIT_TEST_MODE = mode;
	try {
		return await run();
	} finally {
		if (previous === undefined) delete process.env.REVIEW_GIT_TEST_MODE;
		else process.env.REVIEW_GIT_TEST_MODE = previous;
	}
}

function schemaOperations(schema: unknown): string[] {
	const operations = new Set<string>();

	const visit = (value: unknown): void => {
		if (Array.isArray(value)) {
			for (const item of value) visit(item);
			return;
		}
		if (typeof value !== "object" || value === null) return;

		const record = value as Record<string, unknown>;
		const properties = record.properties;
		if (typeof properties === "object" && properties !== null && !Array.isArray(properties)) {
			const operation = (properties as Record<string, unknown>).operation;
			if (typeof operation === "object" && operation !== null && !Array.isArray(operation)) {
				const literal = (operation as Record<string, unknown>).const;
				if (typeof literal === "string") operations.add(literal);
			}
		}

		for (const child of Object.values(record)) visit(child);
	};

	visit(schema);
	return [...operations].sort();
}

function commitSchemas(schema: unknown): Array<Record<string, unknown>> {
	const commits: Array<Record<string, unknown>> = [];

	const visit = (value: unknown): void => {
		if (Array.isArray(value)) {
			for (const item of value) visit(item);
			return;
		}
		if (typeof value !== "object" || value === null) return;

		const record = value as Record<string, unknown>;
		const properties = record.properties;
		if (typeof properties === "object" && properties !== null && !Array.isArray(properties)) {
			for (const name of ["commit", "base"]) {
				const candidate = (properties as Record<string, unknown>)[name];
				if (typeof candidate === "object" && candidate !== null && !Array.isArray(candidate)) {
					commits.push(candidate as Record<string, unknown>);
				}
			}
		}

		for (const child of Object.values(record)) visit(child);
	};

	visit(schema);
	return commits;
}

function resultBody(result: unknown): string {
	const record = result as { content?: Array<{ type?: string; text?: string }> };
	const body = record.content?.[1];
	assert(body?.type === "text" && typeof body.text === "string", "missing Git stdout text block");
	return body.text;
}

function resultDetails(result: unknown): Record<string, unknown> {
	const details = (result as { details?: unknown }).details;
	assert(typeof details === "object" && details !== null && !Array.isArray(details), "missing result details");
	return details as Record<string, unknown>;
}

function paginationDetails(result: unknown): Record<string, unknown> {
	const pagination = resultDetails(result).pagination;
	assert(
		typeof pagination === "object" && pagination !== null && !Array.isArray(pagination),
		"missing pagination details",
	);
	return pagination as Record<string, unknown>;
}

export default function reviewerGitSecurityTest(pi: ExtensionAPI) {
	pi.registerCommand("review-git-security-test", {
		description: "Exercise review_git against hostile repository configuration",
		handler: async (args, ctx) => {
			let summary: Record<string, unknown>;

			try {
				const [base, commit, shortRef, partialCommit, ...extra] = args.trim().split(/\s+/);
				assert(base && commit && shortRef && partialCommit && extra.length === 0, "expected four arguments");
				assert(/^[0-9a-f]{40}$/i.test(base), "base must be a full hexadecimal commit ID");
				assert(/^[0-9a-f]{40}$/i.test(commit), "commit must be a full hexadecimal commit ID");
				assert(/^[0-9a-f]{7,39}$/i.test(shortRef), "short ref must contain 7-39 hexadecimal characters");
				assert(/^[0-9a-f]{40}$/i.test(partialCommit), "partial commit must be a full hexadecimal ID");

				const operations = schemaOperations(reviewGitTool.parameters);
				assert(
					JSON.stringify(operations) === JSON.stringify(EXPECTED_OPERATIONS),
					`unexpected operation schema: ${operations.join(", ")}`,
				);

				const refs = commitSchemas(reviewGitTool.parameters);
				assert(refs.length === 6, `expected six commit/base schemas, found ${refs.length}`);
				for (const schema of refs) {
					assert(schema.minLength === 40, "commit schema minLength must be 40");
					assert(schema.maxLength === 40, "commit schema maxLength must be 40");
					assert(schema.pattern === "^[0-9a-fA-F]{40}$", "commit schema pattern must require 40 hex characters");
				}

				const repository = await realpath(ctx.cwd);
				const expectedDiff = await readFile(requiredEnvironment("REVIEW_GIT_EXPECTED_DIFF_FILE"), "utf8");
				assert(Buffer.byteLength(expectedDiff) > 48 * 1024, "expected diff must exceed 48 KiB");

				const completed: string[] = [];
				const revParse = await reviewGitTool.execute(
					"security-test-rev-parse",
					{ operation: "rev-parse", commit },
					ctx.signal,
					undefined,
					ctx,
				);
				assert(resultBody(revParse) === commit, "rev-parse returned the wrong commit");
				assert(resultDetails(revParse).pagination === undefined, "rev-parse must remain single-page");
				completed.push("rev-parse");

				for (const params of [
					{ operation: "show", commit, path: "tracked.txt" },
					{ operation: "log", base, commit, path: "tracked.txt" },
				] as const) {
					const result = await reviewGitTool.execute("security-test", params, ctx.signal, undefined, ctx);
					const details = resultDetails(result);
					assert(details.operation === params.operation, `wrong operation details for ${params.operation}`);
					assert(details.repository === repository, `wrong repository for ${params.operation}`);
					const pagination = paginationDetails(result);
					assert(pagination.page === 1, `${params.operation} did not default to page 1`);
					assert(pagination.pageSize === 12_000, `${params.operation} used the wrong default page size`);
					completed.push(params.operation);
				}

				let reconstructed = "";
				let page = 1;
				let totalPages = 0;
				let totalCodePoints = 0;
				let stdoutBytes = 0;
				while (true) {
					const result = await reviewGitTool.execute(
						`security-test-diff-${page}`,
						{ operation: "diff", base, commit, path: "large.txt", page, pageSize: PAGE_SIZE },
						ctx.signal,
						undefined,
						ctx,
					);
					const body = resultBody(result);
					const details = resultDetails(result);
					const pagination = paginationDetails(result);
					const bodyCodePoints = [...body].length;

					assert(pagination.page === page, `wrong page metadata for page ${page}`);
					assert(pagination.pageSize === PAGE_SIZE, `wrong page size metadata for page ${page}`);
					assert(pagination.pageCodePoints === bodyCodePoints, `wrong page character count for page ${page}`);
					assert(pagination.pageUtf8Bytes === Buffer.byteLength(body), `wrong page byte count for page ${page}`);
					assert(bodyCodePoints <= PAGE_SIZE, `page ${page} exceeded the requested window`);
					assert(
						pagination.startCodePoint === (page - 1) * PAGE_SIZE,
						`wrong start offset for page ${page}`,
					);
					assert(
						pagination.endCodePointExclusive === (page - 1) * PAGE_SIZE + bodyCodePoints,
						`wrong end offset for page ${page}`,
					);

					if (page === 1) {
						totalPages = pagination.totalPages as number;
						totalCodePoints = pagination.totalCodePoints as number;
						stdoutBytes = details.stdoutBytes as number;
						assert(totalPages > 1, "large diff did not paginate");
					} else {
						assert(pagination.totalPages === totalPages, "total page count changed between requests");
						assert(pagination.totalCodePoints === totalCodePoints, "total character count changed between requests");
						assert(details.stdoutBytes === stdoutBytes, "total byte count changed between requests");
					}

					reconstructed += body;
					const hasNextPage = pagination.hasNextPage === true;
					if (!hasNextPage) {
						assert(pagination.nextPage === undefined, "last page unexpectedly advertised a next page");
						break;
					}
					assert(pagination.nextPage === page + 1, `wrong continuation after page ${page}`);
					page += 1;
					assert(page <= 1_000, "pagination did not terminate");
				}
				completed.push("diff");

				assert(page === totalPages, "did not retrieve every advertised page");
				assert(reconstructed === expectedDiff, "paginated diff did not reconstruct the complete Git output");
				assert(totalCodePoints === [...expectedDiff].length, "total character metadata is incorrect");
				assert(stdoutBytes === Buffer.byteLength(expectedDiff), "total byte metadata is incorrect");

				const outOfRangeError = await rejection(() =>
					reviewGitTool.execute(
						"security-test-out-of-range",
						{
							operation: "diff",
							base,
							commit,
							path: "large.txt",
							page: totalPages + 1,
							pageSize: PAGE_SIZE,
						},
						ctx.signal,
						undefined,
						ctx,
					),
				);
				assert(outOfRangeError.includes("is out of range"), `unexpected page error: ${outOfRangeError}`);

				const invocationLog = requiredEnvironment("REVIEW_GIT_INVOCATION_LOG");
				const invocationsBeforeShortRef = await fileSize(invocationLog);
				const shortRefError = await rejection(() =>
					reviewGitTool.execute(
						"security-test-short-ref",
						{ operation: "rev-parse", commit: shortRef } as never,
						ctx.signal,
						undefined,
						ctx,
					),
				);
				assert(
					shortRefError === "commit must be exactly 40 hexadecimal characters",
					`short ref was not rejected as expected: ${shortRefError}`,
				);
				assert(
					(await fileSize(invocationLog)) === invocationsBeforeShortRef,
					"short ref reached Git before validation",
				);

				const invocationsBeforeTraversal = await fileSize(invocationLog);
				const traversalError = await rejection(() =>
					reviewGitTool.execute(
						"security-test-traversal",
						{ operation: "show", commit, path: "../tracked.txt" },
						ctx.signal,
						undefined,
						ctx,
					),
				);
				assert(traversalError === "path must not contain '..' traversal", `unexpected path error: ${traversalError}`);
				assert(
					(await fileSize(invocationLog)) === invocationsBeforeTraversal,
					"path traversal reached Git before validation",
				);

				const statusError = await rejection(() =>
					reviewGitTool.execute(
						"security-test-status",
						{ operation: "status" } as never,
						ctx.signal,
						undefined,
						ctx,
					),
				);
				assert(
					statusError === "Unsupported read-only Git operation: status",
					`status was not rejected as expected: ${statusError}`,
				);

				const revParsePageError = await rejection(() =>
					reviewGitTool.execute(
						"security-test-rev-parse-page",
						{ operation: "rev-parse", commit, page: 1 } as never,
						ctx.signal,
						undefined,
						ctx,
					),
				);
				assert(
					revParsePageError === "page is not valid for rev-parse",
					`rev-parse pagination was not rejected: ${revParsePageError}`,
				);

				const partialRepository = await realpath(requiredEnvironment("REVIEW_GIT_PARTIAL_REPO"));
				const lazyFetchError = await rejection(() =>
					reviewGitTool.execute(
						"security-test-partial-clone",
						{ operation: "show", commit: partialCommit, path: "large.txt", page: 1, pageSize: PAGE_SIZE },
						ctx.signal,
						undefined,
						{ ...ctx, cwd: partialRepository },
					),
				);
				assert(lazyFetchError.includes("git show failed"), `unexpected partial-clone error: ${lazyFetchError}`);

				const cancelled = new AbortController();
				cancelled.abort();
				const cancellationError = await rejection(() =>
					reviewGitTool.execute(
						"security-test-cancelled",
						{ operation: "rev-parse", commit },
						cancelled.signal,
						undefined,
						ctx,
					),
				);
				assert(cancellationError.includes("was cancelled"), `unexpected cancellation error: ${cancellationError}`);

				const stderrError = await withGitMode("stderr", () =>
					rejection(() =>
						reviewGitTool.execute(
							"security-test-stderr",
							{ operation: "rev-parse", commit },
							ctx.signal,
							undefined,
							ctx,
						),
					),
				);
				assert(
					stderrError.includes("Git diagnostics exceeded 8192 bytes and were truncated"),
					`unexpected stderr truncation error: ${stderrError}`,
				);

				const timeoutError = await withGitMode("timeout", () =>
					rejection(() =>
						reviewGitTool.execute(
							"security-test-timeout",
							{ operation: "rev-parse", commit },
							ctx.signal,
							undefined,
							ctx,
						),
					),
				);
				assert(timeoutError.includes("timed out after 10000ms"), `unexpected timeout error: ${timeoutError}`);

				summary = {
					ok: true,
					operations,
					fullShaSchema: true,
					completed,
					pagination: {
						pageSize: PAGE_SIZE,
						totalPages,
						totalCodePoints,
						stdoutBytes,
						reconstructed: true,
						outOfRangeRejected: true,
					},
					shortRefRejectedBeforeGit: true,
					statusRejected: true,
					revParseSinglePage: true,
					lazyFetchBlocked: true,
					cancellationRejected: true,
					stderrTruncationRejected: true,
					timeoutRejected: true,
					repository,
				};
			} catch (error) {
				summary = { ok: false, error: errorMessage(error) };
			}

			pi.sendMessage(
				{
					customType: "review-git-security-test",
					content: JSON.stringify(summary),
					display: true,
				},
				{ triggerTurn: false },
			);
		},
	});
}
