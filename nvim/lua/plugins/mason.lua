return {
	"williamboman/mason-lspconfig.nvim",
	lazy = true,
	cmd = { "Mason", "MasonInstall", "MasonUpdate" },
	build = ":MasonUpdate",
	dependencies = {
		{
			"williamboman/mason.nvim",
			config = function()
				require("mason").setup({
					ui = {
						icons = {
							package_installed = "✓",
							package_pending = "➜",
							package_uninstalled = "✗",
						},
					},
				})
			end,
		},
		"neovim/nvim-lspconfig",
		{
			"jay-babu/mason-nvim-dap.nvim",
			dependencies = {
				"mfussenegger/nvim-dap",
				"leoluz/nvim-dap-go",
				"suketa/nvim-dap-ruby",
				{ "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
			},
			keys = {
				{
					"<F5>",
					function()
						require("dap").continue()
					end,
					desc = "Debug: Continue",
				},
				{
					"<F10>",
					function()
						require("dap").step_over()
					end,
					desc = "Debug: Step Over",
				},
				{
					"<F11>",
					function()
						require("dap").step_into()
					end,
					desc = "Debug: Step Into",
				},
				{
					"<F12>",
					function()
						require("dap").step_out()
					end,
					desc = "Debug: Step Out",
				},
				{
					"<leader><space>5",
					function()
						require("dap").continue()
					end,
					desc = "Debug: Continue",
				},
				{
					"<leader><space>0",
					function()
						require("dap").step_over()
					end,
					desc = "Debug: Step Over",
				},
				{
					"<leader><space>1",
					function()
						require("dap").step_into()
					end,
					desc = "Debug: Step Into",
				},
				{
					"<leader><space>2",
					function()
						require("dap").step_out()
					end,
					desc = "Debug: Step Out",
				},
				{
					"<Leader><space>b",
					function()
						require("dap").toggle_breakpoint()
					end,
					desc = "Debug: Toggle Breakpoint",
				},
				{
					"<Leader><space>B",
					function()
						require("dap").set_breakpoint()
					end,
					desc = "Debug: Set Breakpoint",
				},
				{
					"<Leader><space>pr",
					function()
						require("dap").repl.open()
					end,
					desc = "Debug: Open REPL",
				},
				{
					"<Leader><space>pl",
					function()
						require("dap").run_last()
					end,
					desc = "Debug: Run Last",
				},
				{
					"<Leader><space>ph",
					function()
						require("dap.ui.widgets").hover()
					end,
					mode = { "n", "v" },
					desc = "Debug: Hover Widget",
				},
				{
					"<Leader><space>pp",
					function()
						require("dap.ui.widgets").preview()
					end,
					mode = { "n", "v" },
					desc = "Debug: Preview Widget",
				},
				{
					"<Leader><space>pf",
					function()
						local widgets = require("dap.ui.widgets")
						widgets.centered_float(widgets.frames)
					end,
					desc = "Debug: Widget Frames",
				},
				{
					"<Leader><space>ps",
					function()
						local widgets = require("dap.ui.widgets")
						widgets.centered_float(widgets.scopes)
					end,
					desc = "Debug: Center Scopes",
				},
			},
			config = function()
				require("mason-nvim-dap").setup({
					ensure_installed = {
						"delve",
					},
					automatic_installation = true,
				})
				require("dap-go").setup()
				require("dapui").setup()
				require("dap-ruby").setup()
				local dap, dapui = require("dap"), require("dapui")
				dap.listeners.before.attach.dapui_config = function()
					dapui.open()
				end
				dap.listeners.before.launch.dapui_config = function()
					dapui.open()
				end
				dap.listeners.before.event_terminated.dapui_config = function()
					dapui.close()
				end
				dap.listeners.before.event_exited.dapui_config = function()
					dapui.close()
				end
			end,
		},
	},
	config = function()
		require("mason-lspconfig").setup({
			automatic_installation = false,
			ensure_installed = {
				-- Language servers
				"ts_ls",
				"lua_ls",
				"gopls",
				"eslint",
				"jsonls",
				"yamlls",
				"jqls",
				"vale_ls",
				"tailwindcss",
				"stylelint_lsp",
			},
		})

		-- Auto-install formatters/linters via Mason registry on first load
		local registry = require("mason-registry")
		local tools = {
			"delve",
			"eslint_d",
			"goimports",
			"golangci-lint",
			"isort",
			"jsonlint",
			"luacheck",
			"prettierd",
			"prettier",
			"shellcheck",
			"stylua",
			"vale",
		}

		for _, tool in ipairs(tools) do
			local p = registry.get_package(tool)
			if not p:is_installed() then
				p:install()
			end
		end
	end,
}
