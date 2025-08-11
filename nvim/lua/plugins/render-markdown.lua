return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
	opts = {},
	config = function()
		require("render-markdown").setup({
			completions = { blink = { enabled = true } },
			file_types = { "markdown", "copilot-chat" },
		})
	end,
}
