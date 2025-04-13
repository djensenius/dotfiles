return {
	"NeogitOrg/neogit",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim", -- required
		"nvim-telescope/telescope.nvim", -- optional
		"sindrets/diffview.nvim", -- optional
	},
	config = true,
	vim.keymap.set("n", "<Leader>gc", ":Neogit commit<CR>", { noremap = true, silent = true }),
}
