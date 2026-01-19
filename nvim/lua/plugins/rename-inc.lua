return {
	"smjonas/inc-rename.nvim",
	event = "VeryLazy",
	keys = {
		{ "<leader><space>P", ":IncRename ", desc = "Incremental Rename" },
	},
	config = function()
		require("inc_rename").setup()
	end,
}
