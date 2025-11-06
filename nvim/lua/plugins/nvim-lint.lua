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
			go = { "golangcilint" },
			python = { "pylint" },
			javascript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			jsonlint = { "jsonlint" },
			lua = { "luacheck" },
			ruby = { "rubocop" },
			svelte = { "eslint_d" },
			typescript = { "eslint_d" },
			typescriptreact = { "eslint_d" },
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

		vim.keymap.set("n", "<leader><space>l", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
