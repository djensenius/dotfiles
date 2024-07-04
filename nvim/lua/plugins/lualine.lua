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
				lualine_b = {
          {
            "filename",
            on_click = function()
              vim.cmd(":Neotree toggle")
            end,
          },
          {
            "branch",
            on_click = function()
              vim.cmd(":Neogit branch")
            end,
          },
          {
            "diff",
            on_click = function()
              vim.cmd(":Neogit")
            end,
          },
          {
          "diagnostics",
            on_click = function()
              vim.cmd(":Trouble diagnostics")
            end,
          },
        },
				lualine_c = {
          { "fileformat" },
          {
            function()
              return require("nvim-navic").get_location()
            end,
            cond = function()
              return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
            end,
            color = utils.get_hlgroup("Comment", nil),
          },
        },
        lualine_x = {
          {
            function()
              return require("lazy.status").updates()
            end,
            cond = require("lazy.status").has_updates,
            color = utils.get_hlgroup("String"),
            on_click = function()
              vim.cmd(":Lazy")
            end,
          },
          {
            function()
              local icon = " "
              return icon
            end,
            cond = function()
              local ok, clients = pcall(vim.lsp.get_clients, { name = "GitHub Copilot" })
              return ok and #clients > 0
            end,
            on_click = function()
              vim.cmd(":CopilotChatToggle")
            end,
            color = utils.get_hlgroup("Conditional"),
          },
          {
            function()
              local icon = " "
              return icon
            end,
            cond = function()
              local ok, clients = pcall(vim.lsp.get_clients, { name = "GitHub Copilot" })
              return ok and #clients == 0
            end,
            on_click = function()
              vim.cmd(":Copilot status")
            end,
            color = utils.get_hlgroup("Comment"),
          },
        },
				lualine_y = {
          {
            function()
              local icon = ""
              return icon
            end,
            on_click = function()
              vim.cmd(":Gitsigns toggle_current_line_blame")
            end,
          },
          {
            "filetype",
            on_click = function()
              vim.cmd(":LspInfo")
            end,
          },
          {
            "progress",
            on_click = function()
              vim.cmd(":AerialToggle")
            end,
          },
        },
				lualine_z = {
					{
            "location",
            on_click = function()
              vim.cmd(":AerialToggle")
            end,
            separator = { right = "" },
            left_padding = 2
          },
				},
			},
			inactive_sections = {
				lualine_a = {
          {
            "filename",
            on_click =  function()
              vim.cmd(":Neotree toggle")
            end,
          }
        },
				lualine_b = { "diagnostics" },
				lualine_c = {"branch"},
				lualine_x = {"diff"},
				lualine_y = {},
				lualine_z = {
          {
            "location",
            on_click = function()
              vim.cmd(":AerialToggle")
            end,
          },
        },
			},
			tabline = {},
			extensions = { "aerial", "lazy", "neo-tree", "trouble" },
		}
	end,
}
