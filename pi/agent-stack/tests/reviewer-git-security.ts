import { realpath } from "node:fs/promises";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { reviewGitTool } from "../extensions/reviewer-git.ts";

const EXPECTED_OPERATIONS = ["diff", "log", "rev-parse", "show"];

function assert(condition: unknown, message: string): asserts condition {
	if (!condition) throw new Error(message);
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

function errorMessage(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}

export default function reviewerGitSecurityTest(pi: ExtensionAPI) {
	pi.registerCommand("review-git-security-test", {
		description: "Exercise review_git against hostile repository configuration",
		handler: async (args, ctx) => {
			let summary: Record<string, unknown>;

			try {
				const [base, commit, ...extra] = args.trim().split(/\s+/);
				assert(base && commit && extra.length === 0, "expected exactly base and commit arguments");
				assert(/^[0-9a-f]{40}$/i.test(base), "base must be a full hexadecimal commit ID");
				assert(/^[0-9a-f]{40}$/i.test(commit), "commit must be a full hexadecimal commit ID");

				const operations = schemaOperations(reviewGitTool.parameters);
				assert(
					JSON.stringify(operations) === JSON.stringify(EXPECTED_OPERATIONS),
					`unexpected operation schema: ${operations.join(", ")}`,
				);

				const cases = [
					{ operation: "rev-parse", commit },
					{ operation: "show", commit, path: "tracked.txt" },
					{ operation: "diff", base, commit, path: "tracked.txt" },
					{ operation: "log", base, commit, path: "tracked.txt" },
				] as const;
				const repository = await realpath(ctx.cwd);
				const completed: string[] = [];

				for (const params of cases) {
					const result = await reviewGitTool.execute("security-test", params, ctx.signal, undefined, ctx);
					const details = result.details as Record<string, unknown>;
					assert(details.operation === params.operation, `wrong operation details for ${params.operation}`);
					assert(details.repository === repository, `wrong repository for ${params.operation}`);
					completed.push(params.operation);
				}

				let statusError = "";
				try {
					await reviewGitTool.execute(
						"security-test-status",
						{ operation: "status" } as never,
						ctx.signal,
						undefined,
						ctx,
					);
				} catch (error) {
					statusError = errorMessage(error);
				}
				assert(
					statusError === "Unsupported read-only Git operation: status",
					`status was not rejected as expected: ${statusError || "no error"}`,
				);

				summary = {
					ok: true,
					operations,
					completed,
					statusRejected: true,
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
