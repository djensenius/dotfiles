return {
	"lseppala/praise.nvim",
	config = function()
		require("praise").setup({
			-- Optional: set a keymap
			keymap = "<leader>gP",
		})
	end,
}
