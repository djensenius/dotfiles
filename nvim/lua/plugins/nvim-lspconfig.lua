return {
	"neovim/nvim-lspconfig",
	dependencies = { "nvim-tree/nvim-web-devicons", "folke/trouble.nvim", "saghen/blink.cmp" },
	event = "VeryLazy",

	config = function()
		require("lspconfig")

		-- Prepare completion
		local on_attach = function(client)
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
        }
      })
		end

		local util = require("lspconfig/util")
    local capabilities = require('blink.cmp').get_lsp_capabilities()
    local yaml_capabilities = vim.lsp.protocol.make_client_capabilities()

    ---@diagnostic disable: undefined-field
    yaml_capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }
    ---@diagnostic enable: undefined-field

		require("lspconfig")["ts_ls"].setup({
			on_attach = on_attach,
			root_dir = util.root_pattern("tsconfig.json"),
			capabilities = capabilities,
		})

		require("lspconfig")["gopls"].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})

    vim.env.SRB_SKIP_GEM_RBIS = 1
		require("lspconfig")["sorbet"].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})

		require("lspconfig")["vale_ls"].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})

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

		require("lspconfig")["yamlls"].setup({
			on_attach = on_attach,
			capabilities = yaml_capabilities,
		})

		require("lspconfig")["jqls"].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})

    require("lspconfig")["jsonls"].setup({
      on_attach = on_attach,
      capabilities = capabilities,
    })
	end,
}
