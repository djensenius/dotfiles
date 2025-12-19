return {
	"stevearc/aerial.nvim",
	event = "VeryLazy",
	opts = {},
	-- Optional dependencies
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	keys = {
		{
			"<leader>af",
			function()
				require("aerial").fzf_lua_picker()
			end,
			desc = "Arial (fzf)",
		},
		{ "<leader>aa", "<cmd>AerialToggle!<cr>", desc = "Arial" },
		{ "<leader>an", "<cmd>AerialNavToggle<cr>", desc = "Arial Navigation" },
	},
}
