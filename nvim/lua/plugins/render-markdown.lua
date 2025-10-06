-- Note: To avoid conflicts with obsidian.nvim, obsidian UI is disabled in obsidian.lua
return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
	event = "VeryLazy",
	opts = {},
	config = function()
		require("render-markdown").setup({
			completions = { blink = { enabled = true } },
			file_types = { "markdown", "copilot-chat" },
		})
	end,
}
