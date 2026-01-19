return {
	"vim-test/vim-test",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"preservim/vimux",
	},
	keys = {
		{ "<leader>tn", ":TestNearest<CR>", desc = "Test Nearest" },
		{ "<leader>tf", ":TestFile<CR>", desc = "Test File" },
		{ "<leader>ts", ":TestSuite<CR>", desc = "Test Suite" },
		{ "<leader>tl", ":TestLast<CR>", desc = "Test Last" },
		{ "<leader>tv", ":TestVisit<CR>", desc = "Test Visit" },
	},
	config = function()
		vim.cmd("let test#strategy = 'vimux'")
	end,
}
