return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"folke/trouble.nvim",
		"saghen/blink.cmp",
		"mason-org/mason-lspconfig.nvim",
	},
	event = { "BufReadPre", "BufNewFile" },

	config = function()
		local capabilities = require("blink.cmp").get_lsp_capabilities()
		local yaml_capabilities = vim.deepcopy(capabilities)

		vim.diagnostic.config({
			severity_sort = true,
			update_in_insert = false,
			virtual_lines = { current_line = true },
			underline = { severity = vim.diagnostic.severity.WARN },
			float = {
				border = "rounded",
				source = "if_many",
			},
			virtual_text = {
				prefix = function(diagnostic)
					if diagnostic.severity == vim.diagnostic.severity.ERROR then
						return ""
					elseif diagnostic.severity == vim.diagnostic.severity.WARN then
						return ""
					elseif diagnostic.severity == vim.diagnostic.severity.INFO then
						return ""
					end
					return ""
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

		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local bufnr = args.buf
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if not client then
					return
				end

				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end

				map("n", "<leader><space>c", function()
					require("fzf-lua").lsp_declarations({ jump1 = false })
				end, "Show declaration")
				map("n", "<leader><space>D", function()
					require("fzf-lua").lsp_definitions({ jump1 = false })
				end, "Show definition")
				map("n", "<leader><space>h", vim.lsp.buf.hover, "Show hover")
				map("n", "<leader><space>i", function()
					require("fzf-lua").lsp_implementations({ jump1 = false })
				end, "Show implementation")
				map("n", "<leader><space>S", vim.lsp.buf.signature_help, "Show signature help")
				map("n", "<leader><space>R", vim.lsp.buf.rename, "Rename")
				map("n", "<leader><space>r", function()
					require("fzf-lua").lsp_references()
				end, "Show references")
				map("n", "<leader><space>d", vim.diagnostic.open_float, "Show diagnostics")
				map("n", "<leader><space>a", function()
					require("fzf-lua").lsp_code_actions()
				end, "Show code actions")
				map("n", "<leader><space>H", function()
					vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
				end, "Toggle inlay hints")

				if
					client:supports_method("textDocument/formatting", bufnr)
					or client:supports_method("textDocument/rangeFormatting", bufnr)
				then
					map("n", "<space>=", function()
						vim.lsp.buf.format({ async = true, bufnr = bufnr })
					end, "Format")
				end
			end,
		})

		---@diagnostic disable: undefined-field
		yaml_capabilities.textDocument.foldingRange = {
			dynamicRegistration = false,
			lineFoldingOnly = true,
		}
		---@diagnostic enable: undefined-field

		vim.lsp.config("ts_ls", {
			capabilities = capabilities,
			settings = {
				typescript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
					},
				},
				javascript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
					},
				},
			},
		})
		vim.lsp.enable("ts_ls")

		vim.lsp.config("gopls", {
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
		vim.lsp.enable("gopls")

		-- local ruby_cmd = { "ruby-lsp" }
		-- vim.lsp.config("ruby_lsp", {
		-- 	cmd = ruby_cmd,
		-- 	capabilities = capabilities,
		-- })
		-- vim.lsp.enable("ruby_lsp")

		vim.env.SRB_SKIP_GEM_RBIS = 1
		vim.lsp.config("sorbet", {
			cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
			capabilities = capabilities,
		})
		vim.lsp.enable("sorbet")

		vim.lsp.config("vale_ls", {
			capabilities = capabilities,
		})
		-- Manual-only: start with :LspValeStart
		vim.api.nvim_create_user_command("LspValeStart", function()
			vim.lsp.enable("vale_ls")
		end, { desc = "Start Vale LSP" })
		vim.lsp.config("eslint", {
			capabilities = capabilities,
		})
		vim.lsp.enable("eslint")

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					runtime = {
						-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim" },
					},
					telemetry = {
						enable = false,
					},
					workspace = {
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME,
						},
					},
				},
			},
			capabilities = capabilities,
		})
		vim.lsp.enable("lua_ls")

		vim.lsp.config("yamlls", {
			capabilities = yaml_capabilities,
		})
		vim.lsp.enable("yamlls")

		vim.lsp.config("jqls", {
			capabilities = capabilities,
		})
		vim.lsp.enable("jqls")

		vim.lsp.config("jsonls", {
			capabilities = capabilities,
		})
		vim.lsp.enable("jsonls")

		vim.lsp.config("tailwindcss", {
			capabilities = capabilities,
		})
		vim.lsp.enable("tailwindcss")

		vim.lsp.config("stylelint_lsp", {
			capabilities = capabilities,
		})
		vim.lsp.enable("stylelint_lsp")
	end,
}
