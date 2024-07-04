return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	opts = function()
    local utils = require("core.utils")
		return {
			options = {
				theme = "catppuccin",
				component_separators = "|",
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = {
					{ "mode", separator = { left = "" }, right_padding = 2 },
				},
				lualine_b = { "filename", "branch", "diff", "diagnostics" },
				lualine_c = { "fileformat" },
        lualine_x = {
                      {
                        require("lazy.status").updates,
                        cond = require("lazy.status").has_updates,
                        color = utils.get_hlgroup("String"),
                      },
                      {
                        function()
                            local icon = " "
                            return icon
                        end,
                        cond = function()
                            local ok, clients = pcall(vim.lsp.get_clients, { name = "GitHub Copilot" })
                            return ok and #clients > 0
                        end,
                        color = utils.get_hlgroup("Conditional"),
                      },
                    },
				lualine_y = { "filetype", "progress" },
				lualine_z = {
					{ "location", separator = { right = "" }, left_padding = 2 },
				},
			},
			inactive_sections = {
				lualine_a = { "filename" },
				lualine_b = { "diagnostics" },
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = { "location" },
			},
			tabline = {},
			extensions = { "neo-tree" },
		}
	end,
}
