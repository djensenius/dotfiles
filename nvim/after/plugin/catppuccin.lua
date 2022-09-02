vim.g.catppuccin_flavour = "mocha" -- latte, frappe, macchiato, mocha

require("catppuccin").setup({
  integrations = {
    treesitter = true,
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
    gitsigns = true,
    lsp_trouble = true,
    dap = {
			enabled = true,
			enable_ui = true,
		},
		neotree = {
			enabled = true,
			show_root = true,
			transparent_panel = false,
		},
    which_key = false,
		indent_blankline = {
			enabled = true,
			colored_indent_levels = false,
		},
  }
})

vim.cmd [[colorscheme catppuccin]]
