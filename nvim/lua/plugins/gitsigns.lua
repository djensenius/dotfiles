-- luacheck: ignore 211 212
return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {},
	config = function()
		require("gitsigns").setup()
		vim.keymap.set("n", "<Leader>gb", ":Gitsigns toggle_current_line_blame<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gs", ":Gitsigns stage_hunk<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gu", ":Gitsigns undo_stage_hunk<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gr", ":Gitsigns reset_hunk<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gR", ":Gitsigns reset_buffer<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gp", ":Gitsigns preview_hunk<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gj", ":Gitsigns next_hunk<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gk", ":Gitsigns prev_hunk<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gl", ":Gitsigns toggle_numhl<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gh", ":Gitsigns toggle_linehl<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gS", ":Gitsigns stage_buffer<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<Leader>gU", ":Gitsigns reset_buffer_index<CR>", { noremap = true, silent = true })
	end,
}
