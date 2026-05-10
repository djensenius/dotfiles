return {
	{
		"mason-org/mason.nvim",
		lazy = false,
		build = ":MasonUpdate",
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		lazy = false,
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			automatic_enable = false,
			ensure_installed = {
				"ts_ls",
				"lua_ls",
				"gopls",
				"eslint",
				"jsonls",
				"yamlls",
				"jqls",
				"vale_ls",
				"tailwindcss",
			},
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
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
				"stylelint-language-server",
				"stylua",
				"vale",
			},
		},
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"mfussenegger/nvim-dap",
			"leoluz/nvim-dap-go",
			"suketa/nvim-dap-ruby",
			{ "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
			{
				"igorlfs/nvim-dap-view",
				dependencies = { "mfussenegger/nvim-dap" },
				cmd = { "DapViewOpen", "DapViewClose", "DapViewToggle", "DapViewWatch" },
				opts = {
					winbar = {
						sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" },
						default_section = "scopes",
						controls = {
							enabled = true,
							position = "right",
						},
					},
					windows = {
						position = "right",
					},
				},
			},
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
			{
				"<Leader><space>pv",
				"<cmd>DapViewToggle<cr>",
				desc = "Debug: Toggle DAP View",
			},
			{
				"<Leader><space>pw",
				"<cmd>DapViewWatch<cr>",
				mode = { "n", "v" },
				desc = "Debug: Watch Expression",
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
}
