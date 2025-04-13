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
		{ "<leader>af", "<cmd>call aerial#fzf()<cr>", desc = "Arial (fzf)" },
		{ "<leader>at", "<cmd>Telescope arial<cr>", desc = "Arial (Telescope)" },
		{ "<leader>aa", "<cmd>AerialToggle!<cr>", desc = "Arial" },
		{ "<leader>an", "<cmd>AerialNavToggle<cr>", desc = "Arial Navigation" },
	},
}
