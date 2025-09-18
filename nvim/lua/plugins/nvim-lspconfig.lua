return {
	"neovim/nvim-lspconfig",
	dependencies = { "nvim-tree/nvim-web-devicons", "folke/trouble.nvim", "saghen/blink.cmp" },
	event = "VeryLazy",

	config = function()
		-- Prepare completion
		local on_attach = function(client, _)
			-- Mappings.
			vim.keymap.set("n", "<leader><space>c", vim.lsp.buf.declaration, { desc = "Go to declaration" })
			vim.keymap.set("n", "<leader><space>D", function()
				require("telescope.builtin").lsp_definitions({ jump_type = "never" })
			end, { desc = "Go to definition" })
			vim.keymap.set("n", "<leader><space>h", vim.lsp.buf.hover, { desc = "Show hover" })
			vim.keymap.set("n", "<leader><space>i", vim.lsp.buf.implementation, { desc = "Go to implementation" })
			vim.keymap.set("n", "<leader><space>S", vim.lsp.buf.signature_help, { desc = "Show signature help" })
			vim.keymap.set("n", "<leader><space>R", vim.lsp.buf.rename, { desc = "Rename" })
			vim.keymap.set("n", "<leader><space>r", function()
				require("telescope.builtin").lsp_references()
			end, { desc = "Show references" })
			vim.keymap.set("n", "<leader><space>d", vim.diagnostic.open_float, { desc = "Show diagnostics" })
			vim.keymap.set("n", "<leader><space>i", vim.lsp.buf.code_action, { desc = "Show code actions" })

			-- Set some keybinds conditional on server capabilities
			if client.server_capabilities.document_formatting then
				vim.keymap.set("n", "<space>=", vim.lsp.buf.formatting, { desc = "Format" })
			elseif client.server_capabilities.document_range_formatting then
				vim.keymap.set("n", "<space>=", vim.lsp.buf.formatting, { desc = "Format" })
			end

			-- Virtual line stuff
			vim.diagnostic.config({
				virtual_lines = { current_line = true },
				underline = { severity = vim.diagnostic.severity.WARN }, -- underlines for warnings and errors only
				virtual_text = {
					prefix = function(diagnostic)
						if diagnostic.severity == vim.diagnostic.severity.ERROR then
							return ""
						elseif diagnostic.severity == vim.diagnostic.severity.WARN then
							return ""
						elseif diagnostic.severity == vim.diagnostic.severity.INFO then
							return ""
						else
							return ""
						end
					end,
					source = "if_many",
					spacing = 4,
				},
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "",
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.INFO] = "",
						[vim.diagnostic.severity.HINT] = "",
					},
				},
			})
		end

		local capabilities = require("blink.cmp").get_lsp_capabilities()
		local yaml_capabilities = vim.lsp.protocol.make_client_capabilities()

		---@diagnostic disable: undefined-field
		yaml_capabilities.textDocument.foldingRange = {
			dynamicRegistration = false,
			lineFoldingOnly = true,
		}
		---@diagnostic enable: undefined-field

		vim.lsp.config('ts_ls', {
			on_attach = on_attach,
			root_dir = function(fname)
				return vim.fs.find('tsconfig.json', { path = fname, upward = true })[1] and vim.fs.dirname(vim.fs.find('tsconfig.json', { path = fname, upward = true })[1])
			end,
			capabilities = capabilities,
		})
		vim.lsp.enable('ts_ls')

		vim.lsp.config('gopls', {
			on_attach = on_attach,
			capabilities = capabilities,
			settings = {
				gopls = {
					gofumpt = true,
					staticcheck = true,
					usePlaceholders = true,
					analyses = {
						unusedparams = true,
						fieldalignment = true,
						shadow = true,
					},
					codelenses = {
						test = true,
						tidy = true,
						upgrade_dependency = true,
					},
					completeUnimported = true,
					directoryFilters = { "-vendor" },
					buildFlags = { "-tags=integration" },
				},
			},
		})
		vim.lsp.enable('gopls')

		vim.env.SRB_SKIP_GEM_RBIS = 1
		vim.lsp.config('sorbet', {
			on_attach = on_attach,
			capabilities = capabilities,
		})
		vim.lsp.enable('sorbet')

		vim.lsp.config('vale_ls', {
			on_attach = on_attach,
			capabilities = capabilities,
		})
		vim.lsp.enable('vale_ls')

		vim.lsp.config('eslint', {
			on_attach = on_attach,
			root_dir = function(fname)
				return vim.fs.find('package.json', { path = fname, upward = true })[1] and vim.fs.dirname(vim.fs.find('package.json', { path = fname, upward = true })[1])
			end,
			capabilities = capabilities,
		})
		vim.lsp.enable('eslint')

		vim.lsp.config('lua_ls', {
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
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME,
							-- Depending on the usage, you might want to add additional paths here.
							"${3rd}/luv/library",
							-- "${3rd}/busted/library",
						},
					},
					telemetry = {
						enable = false,
					},
				},
			},
			on_attach = on_attach,
			capabilities = capabilities,
		})
		vim.lsp.enable('lua_ls')

		vim.lsp.config('yamlls', {
			on_attach = on_attach,
			capabilities = yaml_capabilities,
		})
		vim.lsp.enable('yamlls')

		vim.lsp.config('jqls', {
			on_attach = on_attach,
			capabilities = capabilities,
		})
		vim.lsp.enable('jqls')

		vim.lsp.config('jsonls', {
			on_attach = on_attach,
			capabilities = capabilities,
		})
		vim.lsp.enable('jsonls')
	end,
}
