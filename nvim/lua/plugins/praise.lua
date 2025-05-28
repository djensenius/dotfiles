return {
	"lseppala/praise.nvim",
	event = "VeryLazy",
	config = function()
		require("praise").setup({
			-- Optional: set a keymap
			keymap = "<leader>gP",
		})
	end,
}
