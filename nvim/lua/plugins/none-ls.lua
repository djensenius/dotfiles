return {
	"nvimtools/none-ls.nvim",
	event = "VeryLazy",
	config = function()
		local null_ls = require("null-ls")
		local conditional = function(fn)
			local utils = require("null-ls.utils").make_conditional_utils()
			return fn(utils)
		end

		null_ls.setup({
			debug = false,
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.eslint,
				conditional(function(utils)
					return utils.root_has_file("Gemfile") and null_ls.builtins.formatting.rubocop.with({})
						or null_ls.builtins.formatting.rubocop
				end),

				-- Same as above, but with diagnostics.rubocop to make sure we use the proper rubocop version for the project
				conditional(function(utils)
					return utils.root_has_file("Gemfile") and null_ls.builtins.diagnostics.rubocop.with({})
						or null_ls.builtins.diagnostics.rubocop
				end),
			},
			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
					vim.keymap.set("n", "<Leader>fmt", function()
						vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
					end, { buffer = bufnr, desc = "[lsp] format" })
				end
			end,
		})
	end,
}
