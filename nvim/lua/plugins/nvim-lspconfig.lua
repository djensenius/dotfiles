return {
	"neovim/nvim-lspconfig",
	dependencies = { "nvim-tree/nvim-web-devicons", "folke/trouble.nvim", "hrsh7th/cmp-nvim-lsp" },
	event = "VeryLazy",

	config = function()
		require("lspconfig")

		-- Prepare completion
		local on_attach = function(client)
			-- Mappings.
			vim.keymap.set("n", "<leader><space>D", vim.lsp.buf.declaration, { desc = "Go to declaration" })
			vim.keymap.set("n", "<leader><space>f", vim.lsp.buf.definition, { desc = "Go to definition" })
			vim.keymap.set("n", "<leader><space>h", vim.lsp.buf.hover, { desc = "Show hover" })
			vim.keymap.set("n", "<leader><space>i", vim.lsp.buf.implementation, { desc = "Go to implementation" })
			vim.keymap.set("n", "<leader><space>S", vim.lsp.buf.signature_help, { desc = "Show signature help" })
			vim.keymap.set("n", "<leader><space>R", vim.lsp.buf.rename, { desc = "Rename" })
			vim.keymap.set("n", "<leader><space>r", vim.lsp.buf.references, { desc = "Show references" })
			vim.keymap.set("n", "<leader><space>d", vim.diagnostic.open_float, { desc = "Show diagnostics" })
			vim.keymap.set("n", "<leader><space>i", vim.lsp.buf.code_action, { desc = "Show code actions" })
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })

			-- Set some keybinds conditional on server capabilities
			if client.server_capabilities.document_formatting then
				vim.keymap.set("n", "<space>=", vim.lsp.buf.formatting, { desc = "Format" })
			elseif client.server_capabilities.document_range_formatting then
				vim.keymap.set("n", "<space>=", vim.lsp.buf.formatting, { desc = "Format" })
			end
		end

		local util = require("lspconfig/util")
		local capabilities = require("cmp_nvim_lsp").default_capabilities()
		require("lspconfig")["tsserver"].setup({
			on_attach = on_attach,
			root_dir = util.root_pattern("tsconfig.json"),
			capabilities = capabilities,
		})

		require("lspconfig")["sorbet"].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})

		--[[
    require('lspconfig')['solargraph'].setup{
      on_attach = on_attach,
      flags = lsp_flags,
    }
    --]]

		require("lspconfig")["eslint"].setup({
			on_attach = on_attach,
			root_dir = util.root_pattern("package.json"),
			capabilities = capabilities,
		})

		require("lspconfig")["lua_ls"].setup({
			settings = {
				Lua = {
					runtime = {
						-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						-- Make the server aware of Neovim runtime files
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = "Disable",
					},
					telemetry = {
						enable = false,
					},
				},
			},
			on_attach = on_attach,
			capabilities = capabilities,
		})

		local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
		end

		require("trouble").setup({
			signs = {
				-- icons / text used for a diagnostic
				error = "",
				warning = "",
				hint = "",
				information = "",
				other = "",
			},
		})
	end,
}
