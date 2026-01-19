return {
	"nvim-neo-tree/neo-tree.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	event = "VeryLazy",
	keys = {
		{ "<leader>tg", ":Neotree toggle<CR>", desc = "Toggle Neo-tree" },
		{ "<leader>tF", ":Neotree filesystem reveal left<CR>", desc = "Reveal File in Neo-tree" },
		{ "<leader>tb", ":Neotree buffers reveal float<CR>", desc = "Neo-tree Buffers" },
	},
	config = function()
		require("neo-tree").setup({
			default_component_configs = {
				icon = {
					folder_empty = "󰜌",
					folder_empty_open = "󰜌",
				},
				git_status = {
					symbols = {
						renamed = "󰁕",
						unstaged = "󰄱",
					},
				},
			},
			document_symbols = {
				kinds = {
					File = { icon = "󰈙", hl = "Tag" },
					Namespace = { icon = "󰌗", hl = "Include" },
					Package = { icon = "󰏖", hl = "Label" },
					Class = { icon = "󰌗", hl = "Include" },
					Property = { icon = "󰆧", hl = "@property" },
					Enum = { icon = "󰒻", hl = "@number" },
					Function = { icon = "󰊕", hl = "Function" },
					String = { icon = "󰀬", hl = "String" },
					Number = { icon = "󰎠", hl = "Number" },
					Array = { icon = "󰅪", hl = "Type" },
					Object = { icon = "󰅩", hl = "Type" },
					Key = { icon = "󰌋", hl = "" },
					Struct = { icon = "󰌗", hl = "Type" },
					Operator = { icon = "󰆕", hl = "Operator" },
					TypeParameter = { icon = "󰊄", hl = "Type" },
					StaticMethod = { icon = "󰠄 ", hl = "Function" },
				},
			},
			-- Add this section only if you've configured source selector.
			source_selector = {
				winbar = true,
				sources = {
					{ source = "filesystem", display_name = "󰉓 Files" },
					{ source = "git_status", display_name = "󰊢 Git" },
					{ source = "buffers", display_name = "󰉋 Buffers" },
					{ source = "document_symbols", display_name = " Symbols" },
				},
				content_layout = "center",
				highlight_tab = "NeoTreeTabInactive", -- string
				highlight_tab_active = "NeoTreeTabActive", -- string
				highlight_background = "NeoTreeTabInactive", -- string
				highlight_separator = "ActiveWindow", -- string
				highlight_separator_active = "NeoTreeTabSeparatorActive", -- string
			},
			sources = {
				"filesystem",
				"buffers",
				"git_status",
				"document_symbols",
			},
		})
	end,
}
