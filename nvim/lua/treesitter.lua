require('nvim-treesitter.configs').setup({
	ensure_installed = "maintained",

	highlight = {
		enable = true,
	},

	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "gnn",
			node_incremental = "gnn",
			scope_incremental = "gnc",
			node_decremental = "gnd",
		},
	},

	indent = {
		enable = true
	},
})

