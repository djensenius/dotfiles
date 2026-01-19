return {
	"christoomey/vim-tmux-navigator",
	event = "VeryLazy",
	keys = {
		{ "<c-h>", ":TmuxNavigateLeft<CR>", desc = "Window Left" },
		{ "<c-j>", ":TmuxNavigateDown<CR>", desc = "Window Down" },
		{ "<c-k>", ":TmuxNavigateUp<CR>", desc = "Window Up" },
		{ "<c-l>", ":TmuxNavigateRight<CR>", desc = "Window Right" },
	},
}
