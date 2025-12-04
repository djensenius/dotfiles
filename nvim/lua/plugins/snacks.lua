return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		bigfile = { enabled = true },
		image = { enabled = true },
		indent = { enabled = false },
		notifier = { enabled = true },
		quickfile = { enabled = true },
		scroll = { enabled = true },
	},
	keys = {
		{
			"<leader>fn",
			function()
				require("snacks").notifier.show_history()
			end,
			desc = "Notification History",
		},
	},
}
