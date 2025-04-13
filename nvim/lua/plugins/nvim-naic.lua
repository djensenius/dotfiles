return {
	"smiteshp/nvim-navic",
	event = "VeryLazy",
	config = function()
		require("nvim-navic").setup({
			lsp = {
				auto_attach = true,
			},
			separator = " 󰁔 ",
		})
	end,
}
