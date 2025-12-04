return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			transparent_background = false,
			background = {
				light = "latte",
				dark = "mocha",
			},
			compile = {
				enabled = true,
			},
			copilot = true,
			dim_inactive = {
				enabled = true,
			},
			integrations = {
				aerial = true,
				alpha = true,
				blink_cmp = true,
				copilot_vim = true,
				dap = {
					enabled = true,
					enable_ui = true,
				},
				fzf = true,
				gitgraph = true,
				gitsigns = true,
				indent_blankline = {
					enabled = true,
					colored_indent_levels = true,
				},
				lsp_trouble = true,
				mason = true,
				neotree = {
					enabled = true,
					show_root = true,
					transparent_panel = false,
				},
				native_lsp = {
					enabled = true,
					virtual_text = {
						errors = { "italic" },
						hints = { "italic" },
						warnings = { "italic" },
						information = { "italic" },
					},
					underlines = {
						errors = { "underline" },
						hints = { "underline" },
						warnings = { "underline" },
						information = { "underline" },
					},
				},
				neogit = true,
				notify = true,
				noice = true,
				snacks = {
					enabled = true,
				},
				telescope = {
					enabled = false,
				},
				treesitter = true,
				which_key = true,
			},
		})
		vim.cmd([[colorscheme catppuccin]])
	end,
}
