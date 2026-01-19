return {
	"NeogitOrg/neogit",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim", -- required
		"ibhagwan/fzf-lua", -- optional
		"sindrets/diffview.nvim", -- optional
	},
	config = true,
	keys = {
		{ "<leader>gc", ":Neogit commit<CR>", desc = "Neogit commit" },
	},
}
