return {
	"mfussenegger/nvim-lint",
	event = {
		"BufReadPre",
		"BufNewFile",
	},
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			fish = { "fish" },
			pkl = { "pkl" },
			python = { "pylint" },
			javascript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			jsonlint = { "jsonlint" },
			lua = { "selene" },
			ruby = { "rubocop" },
			svelte = { "eslint_d" },
			typescript = { "eslint_d" },
			typescriptreact = { "eslint_d" },
		}

		-- Pkl linter: uses `pkl eval` to catch errors the LSP misses
		-- (e.g. missing required properties — apple/pkl-lsp#103).
		-- Since we always evaluate the current buffer, every reported error
		-- is relevant: attach it to a matching source line in this buffer if
		-- there is one, otherwise to line 1 with the render path for context.
		lint.linters.pkl = {
			name = "pkl",
			cmd = "pkl",
			stdin = false,
			args = { "eval" },
			stream = "stderr",
			ignore_exitcode = true,
			parser = function(output, bufnr)
				local diagnostics = {}
				if not output or output == "" then
					return diagnostics
				end
				local bufpath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
				local lines = vim.split(output, "\n", { plain = true })

				local blocks = {}
				local cur
				local pending
				for _, line in ipairs(lines) do
					if line:match("^.- Pkl Error .-$") and line:match("Pkl Error") then
						cur = { msg = nil, locs = {}, render = nil }
						pending = nil
						table.insert(blocks, cur)
					elseif cur then
						if not cur.msg and vim.trim(line) ~= "" then
							cur.msg = vim.trim(line)
						end
						local gutter = line:match("^(%d+) | ")
						if gutter then
							pending = { num = tonumber(gutter), prefix = #gutter + 3 }
						end
						local caret = line:match("^(%s*%^+)%s*$")
						if caret and pending then
							pending.caret_start = (line:find("%^") or 1)
						end
						local file, atline = line:match("at .- %(file://([^,]+), line (%d+)%)")
						if file then
							local loc = { file = file, line = tonumber(atline) }
							if pending and pending.num == loc.line then
								loc.col = math.max((pending.caret_start or 1) - pending.prefix - 1, 0)
							end
							table.insert(cur.locs, loc)
							pending = nil
						end
						local rpath = line:match("rendering path `(.-)` of module")
						if rpath then
							cur.render = rpath
						end
					end
				end

				for _, block in ipairs(blocks) do
					local msg = block.msg or "Pkl error"
					-- Prefer a source location inside the current buffer.
					local here
					for _, loc in ipairs(block.locs) do
						if vim.fn.resolve(loc.file) == bufpath then
							here = loc
							break
						end
					end
					if here then
						table.insert(diagnostics, {
							lnum = here.line - 1,
							col = here.col or 0,
							severity = vim.diagnostic.severity.ERROR,
							message = msg,
							source = "pkl",
						})
					else
						-- Error originates in an imported/amended file; surface it
						-- on line 1 with the render path so it isn't lost.
						if block.render then
							msg = block.render .. ": " .. msg
						end
						table.insert(diagnostics, {
							lnum = 0,
							col = 0,
							severity = vim.diagnostic.severity.ERROR,
							message = msg,
							source = "pkl",
						})
					end
				end
				return diagnostics
			end,
		}

		-- Use system rubocop (from mise) instead of Mason's version
		lint.linters.rubocop.cmd = "rubocop"

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})
	end,
	keys = {
		{
			"<leader><space>l",
			function()
				require("lint").try_lint()
			end,
			desc = "Trigger linting for current file",
		},
	},
}
