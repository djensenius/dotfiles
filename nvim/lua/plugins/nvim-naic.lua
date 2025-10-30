return {
	"smiteshp/nvim-navic",
	event = "VeryLazy",
	config = function()
		require("nvim-navic").setup({
			lsp = {
				auto_attach = true,
			},
			preference = {
				"sorbet",
				"lua_ls",
				"gopls",
				"tsserver",
				-- add others if you use navic with them
			},
			separator = " 󰁔 ",
		})
	end,
}
