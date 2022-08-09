require'nvim-treesitter.configs'.setup({
	ensure_installed = { "rust", "go", "lua", "bash", "css", "dockerfile", "fish", "graphql", "html", "javascript", "jsdoc", "json", "python", "ruby", "scss", "typescript", "vim", "supercollider"},

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

