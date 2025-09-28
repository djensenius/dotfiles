return {
	{ "danro/rename.vim", event = { "BufReadPost", "BufNewFile" } },
	{ "tpope/vim-endwise", event = { "BufReadPost", "BufNewFile" } },
	{ "tpope/vim-repeat", event = { "BufReadPost", "BufNewFile" } },
	{ "kosayoda/nvim-lightbulb", event = { "BufReadPost", "BufNewFile" } },
	{ "github/copilot.vim", 
		event = { "VeryLazy" },
		config = function()
			-- Enable Copilot by default
			vim.g.copilot_enabled = true
		end
	},
	{ "lukoshkin/trailing-whitespace", event = { "BufReadPost", "BufNewFile" } },
}
