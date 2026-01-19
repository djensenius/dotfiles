return {
	"tpope/vim-obsession",
	keys = {
		{ "<leader>ss", ":Obsession<CR>", desc = "Start/Stop Session" },
		{ "<leader>sr", ":so Session.vim<CR>", desc = "Restore Session" },
	},
	config = function()
		vim.sessions_dir = "~/.config/vim-sessions"
	end,
}
