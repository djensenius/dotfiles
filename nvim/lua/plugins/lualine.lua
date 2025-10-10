return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	opts = function()
		local utils = require("core.utils")
		local function lualine_mason_updates()
			local registry = require("mason-registry")
			local installed_packages = registry.get_installed_package_names()
			local upgrades_available = false
			local packages_outdated = 0

			for _, pkg in pairs(installed_packages) do
				local p = registry.get_package(pkg)
				if p then
					local latest_version = p:get_latest_version()
					local installed_version = p:get_installed_version()
					if installed_version ~= latest_version then
						upgrades_available = true
						packages_outdated = packages_outdated + 1
					end
				end
			end

			if upgrades_available then
				return packages_outdated
			else
				return ""
			end
		end
		return {
			options = {
				theme = "catppuccin",
				component_separators = { left = "|", right = "|" },
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
							local mode = vim.fn.mode()
							return #mode > 0 and "%S" or ""
						end,
						padding = { left = 1, right = 1 },
						draw_empty = false,
						cond = function()
							local mode = vim.fn.mode()
							return mode ~= "i"
						end,
						separator = { left = "" },
					},
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
						lualine_mason_updates,
						icon = "󱌢",
						on_click = function()
							vim.cmd("Mason")
						end,
						color = utils.get_hlgroup("String"),
					},
					{
						"lsp_status",
						ignore_lsp = { "GitHub Copilot" },
						icon = "", -- f013
						symbols = {
							-- Standard unicode symbols to cycle through for LSP progress:
							spinner = { "∙", "●", "◉", "◎" },
							-- spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
							done = "✓",
							-- Delimiter inserted between LSP names:
							separator = " ",
						},
						on_click = function()
							vim.cmd(":LspInfo")
						end,
					},
				},
				lualine_y = {
					{
						function()
							local icon = ""
							return icon
						end,
						on_click = function()
							vim.cmd(":Gitsigns toggle_current_line_blame")
						end,
						draw_empty = false,
					},
					{
						"filetype",
						on_click = function()
							vim.cmd(":LspInfo")
						end,
						cond = function()
							return vim.bo.filetype and #vim.bo.filetype > 0
						end,
						draw_empty = false,
					},
					{
						function()
							local icon = " "
							return icon
						end,
						cond = function()
							local status = require("sidekick.status")
							return status.get() ~= nil
						end,
						on_click = function()
							vim.cmd(":CopilotChatToggle")
						end,
						color = utils.get_hlgroup("Conditional"),
					},
					{
						function()
							local icon = " "
							return icon
						end,
						cond = function()
							local ok, clients = pcall(vim.lsp.get_clients, { name = "GitHub Copilot" })
							return ok and #clients == 0
						end,
						on_click = function()
							vim.cmd(":Copilot status")
						end,
						-- color = utils.get_hlgroup("String"),
						color = function()
							local status = require("sidekick.status").get()
							if status then
								return status.kind == "Error" and "DiagnosticError"
									or status.busy and "DiagnosticWarn"
									or "Special"
							end
							return utils.get_hlgroup("Error")
						end,
					},
					{
						"progress",
						on_click = function()
							vim.cmd(":AerialToggle")
						end,
						cond = function()
							return vim.fn.line("$") > 1 or #vim.fn.getline(1) > 0
						end,
						draw_empty = false,
					},
				},
				lualine_z = {
					{
						"location",
						on_click = function()
							vim.cmd(":AerialToggle")
						end,
						separator = { right = "" },
						left_padding = 2,
					},
				},
			},
			inactive_sections = {
				lualine_a = {
					{
						"filename",
						on_click = function()
							vim.cmd(":Neotree toggle")
						end,
					},
				},
				lualine_b = { "diagnostics" },
				lualine_c = { "branch" },
				lualine_x = { "diff" },
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
			extensions = { "aerial", "lazy", "fzf", "neo-tree", "trouble" },
		}
	end,
}
