return {
	"folke/noice.nvim",
	event = "VeryLazy",
	opts = {
		cmdline = {
			view = "cmdline",
		},
		presets = {
			inc_rename = true,
		},
		lsp = {
			-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
		},
		routes = {
			{
				filter = {
					event = "msg_show",
					kind = "",
					find = "written",
				},
				opts = { skip = true },
			},
			{
				filter = {
					event = "msg_show",
					kind = "wmsg",
					find = "BOTTOM",
				},
				opts = { skip = true },
			},
			{
				filter = {
					event = "msg_show",
					kind = "emsg",
					find = "E486",
				},
				opts = { skip = true },
			},
			{
				filter = {
					event = "lsp",
					kind = "progress",
					cond = function(message)
						local client = vim.tbl_get(message.opts, "progress", "client")
						return client == "lua_ls"
					end,
				},
				opts = { skip = true },
			},
		},
		-- add any options here
	},
	dependencies = {
		-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
		"MunifTanjim/nui.nvim",
		-- OPTIONAL:
		--   `nvim-notify` is only needed, if you want to use the notification view.
		--   If not available, we use `mini` as the fallback
		"rcarriga/nvim-notify",
	},
}
