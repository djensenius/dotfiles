return {
	"NeogitOrg/neogit",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim", -- required
		"ibhagwan/fzf-lua", -- optional
		"sindrets/diffview.nvim", -- optional
	},
	config = true,
	vim.keymap.set("n", "<Leader>gc", ":Neogit commit<CR>", { noremap = true, silent = true }),
}
