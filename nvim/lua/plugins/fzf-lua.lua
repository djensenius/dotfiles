return {
	"ibhagwan/fzf-lua",
	event = "VeryLazy",
	-- optional for icon support
	dependencies = { "nvim-tree/nvim-web-devicons", "elanmed/fzf-lua-frecency.nvim" },
	keys = {
		{
			"<c-G>",
			function()
				require("fzf-lua").live_grep()
			end,
			desc = "Files",
		},
		{
			"<c-P>",
			function()
				require("fzf-lua").files({ line_query = true })
			end,
			desc = "Files",
		},
		{
			"<leader>fzg",
			function()
				require("fzf-lua").live_grep()
			end,
			desc = "Live grep",
		},
		{
			"<leader>fzf",
			function()
				require("fzf-lua").frecency({ cwd_only = true })
			end,
			desc = "Frecency",
		},
		{
			"<leader>fzF",
			function()
				require("fzf-lua").files({ line_query = true })
			end,
			desc = "Files",
		},
		{
			"<leader>fzr",
			function()
				require("fzf-lua").resume()
			end,
			desc = "Resume",
		},
		{
			"<leader>fzo",
			function()
				require("fzf-lua").oldfiles()
			end,
			desc = "Old files",
		},
		{
			"<leader>fzG",
			function()
				require("fzf-lua").git_status()
			end,
			desc = "Git Status",
		},
		{
			"<leader>fzq",
			function()
				require("fzf-lua").quickfix()
			end,
			desc = "Quickfix",
		},
		{
			"<leader>fzb",
			function()
				require("fzf-lua").buffers()
			end,
			desc = "Buffers",
		},
		{
			"<leader>fzz",
			function()
				require("fzf-lua").global()
			end,
			desc = "Global",
		},
		{
			"<leader>fzk",
			function()
				require("fzf-lua").keymaps()
			end,
			desc = "Keymaps",
		},
		{
			"<leader>fzu",
			function()
				require("fzf-lua").undotree()
			end,
			desc = "Undotree",
		},
		{
			"<leader>fzlr",
			function()
				require("fzf-lua").lsp_references()
			end,
			desc = "References",
		},
		{
			"<leader>fzlD",
			function()
				require("fzf-lua").lsp_definitions()
			end,
			desc = "Definitions",
		},
		{
			"<leader>fzlc",
			function()
				require("fzf-lua").lsp_declarations()
			end,
			desc = "Declarations",
		},
		{
			"<leader>fzlt",
			function()
				require("fzf-lua").lsp_typedefs()
			end,
			desc = "Type Definitions",
		},
		{
			"<leader>ff",
			function()
				require("fzf-lua").files()
			end,
			desc = "Files",
		},
		{
			"<leader>fg",
			function()
				require("fzf-lua").live_grep()
			end,
			desc = "Live grep",
		},
		{
			"<leader>fb",
			function()
				require("fzf-lua").buffers()
			end,
			desc = "Buffers",
		},
		{
			"<leader>fh",
			function()
				require("fzf-lua").help_tags()
			end,
			desc = "Help tags",
		},
		{
			"<leader>fd",
			function()
				require("fzf-lua").lsp_definitions({ jump1 = false })
			end,
			desc = "Definitions",
		},
		{
			"<leader>fr",
			function()
				require("fzf-lua").lsp_references()
			end,
			desc = "References",
		},
		{
			"gr",
			function()
				require("fzf-lua").lsp_references({ jump1 = true, ignore_current_line = true })
			end,
			desc = "LSP References",
		},
		{
			"gd",
			function()
				require("fzf-lua").lsp_definitions({ jump1 = true })
			end,
			desc = "LSP Definitions",
		},
	},
	config = function()
		-- calling `setup` is optional for customization
		local frecency = require("fzf-lua-frecency")
		frecency.setup()
		require("fzf-lua").setup({ "default-title" })
		require("fzf-lua").register_ui_select()
	end,
}
