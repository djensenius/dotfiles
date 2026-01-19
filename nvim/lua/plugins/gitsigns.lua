-- luacheck: ignore 211 212
return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {},
	keys = {
		{ "<leader>gb", ":Gitsigns toggle_current_line_blame<CR>", desc = "Toggle Line Blame" },
		{ "<leader>gs", ":Gitsigns stage_hunk<CR>", desc = "Stage Hunk" },
		{ "<leader>gu", ":Gitsigns undo_stage_hunk<CR>", desc = "Undo Stage Hunk" },
		{ "<leader>gr", ":Gitsigns reset_hunk<CR>", desc = "Reset Hunk" },
		{ "<leader>gR", ":Gitsigns reset_buffer<CR>", desc = "Reset Buffer" },
		{ "<leader>gp", ":Gitsigns preview_hunk<CR>", desc = "Preview Hunk" },
		{ "<leader>gj", ":Gitsigns next_hunk<CR>", desc = "Next Hunk" },
		{ "<leader>gk", ":Gitsigns prev_hunk<CR>", desc = "Previous Hunk" },
		{ "<leader>gl", ":Gitsigns toggle_numhl<CR>", desc = "Toggle Num HL" },
		{ "<leader>gh", ":Gitsigns toggle_linehl<CR>", desc = "Toggle Line HL" },
		{ "<leader>gS", ":Gitsigns stage_buffer<CR>", desc = "Stage Buffer" },
		{ "<leader>gU", ":Gitsigns reset_buffer_index<CR>", desc = "Reset Buffer Index" },
	},
	config = function()
		require("gitsigns").setup()
	end,
}
