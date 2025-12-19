return {
	"MeanderingProgrammer/treesitter-modules.nvim",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	config = function()
		require("treesitter-modules").setup({
			auto_install = true,
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
				enable = true,
			},
		})
	end,
}
