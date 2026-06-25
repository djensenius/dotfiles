return {
	"arborist-ts/arborist.nvim",
	lazy = false,
	priority = 100,
	config = function()
		require("arborist").setup({
			install_popular = true,
			update_cadence = "weekly",
			ensure_installed = require("config.treesitter-parsers"),
		})
	end,
}
