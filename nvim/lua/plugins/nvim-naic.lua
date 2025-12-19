return {
	"smiteshp/nvim-navic",
	event = "VeryLazy",
	config = function()
		require("nvim-navic").setup({
			icons = {
				File = " ",
				Module = " ",
				Namespace = " ",
				Package = " ",
				Class = " ",
				Method = " ",
				Property = " ",
				Field = " ",
				Constructor = " ",
				Enum = " ",
				Interface = " ",
				Function = " ",
				Variable = " ",
				Constant = " ",
				String = " ",
				Number = " ",
				Boolean = " ",
				Array = " ",
				Object = " ",
				Key = " ",
				Null = " ",
				EnumMember = " ",
				Struct = " ",
				Event = " ",
				Operator = " ",
				TypeParameter = " ",
			},
			preference = {
				"sorbet",
				"lua_ls",
				"gopls",
				"tsserver",
				-- add others if you use navic with them
			},
			lsp = {
				auto_attach = true,
			},
			separator = " 󰁔 ",
		})
	end,
}
