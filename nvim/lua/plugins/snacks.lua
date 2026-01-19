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
		dashboard = {
			enabled = true,
			sections = {
				{
					text = [[
    (q\_/p)
.-.  |. .|                            (\
   \ =\,/=                           (\_\_^__o
    )/ _ \                 ___        `-'/ `_/
   (/\):(/\               '`--\________/   |
    \_   _/          '        /            |
    `""^""`      `    .  ' `-`/.----------'\^-'
]],
					hl = "header",
					padding = 1,
				},
				{ section = "keys", gap = 0, padding = 1 },
				{
					text = " v" .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
					hl = "SnacksDashboardFooter",
					align = "center",
				},
				{
					text = "󰌢 " .. vim.env.USER .. "@" .. vim.fn.hostname(),
					hl = "SnacksDashboardFooter",
					align = "center",
				},
				{ section = "startup" },
			},
			preset = {
				keys = {
					{
						icon = " ",
						key = "f",
						desc = "Find file",
						action = function()
							require("fzf-lua").frecency({ cwd_only = true })
						end,
					},
					{
						icon = " ",
						key = "r",
						desc = "Recent files",
						action = function()
							require("fzf-lua").frecency()
						end,
					},
					{ icon = " ", key = "R", desc = "Restore session", action = ":so Session.vim" },
					{
						icon = " ",
						key = "g",
						desc = "Find text",
						action = function()
							require("fzf-lua").live_grep()
						end,
					},
					{
						icon = " ",
						key = "G",
						desc = "Git Status",
						action = function()
							require("fzf-lua").git_status()
						end,
					},
					{ icon = " ", key = "t", desc = "Open file tree", action = ":Neotree" },
					{ icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
					{
						icon = " ",
						key = "d",
						desc = "Git Graph",
						action = function()
							require("gitgraph").draw({}, { all = true, max_count = 5000 })
						end,
					},
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
			},
		},
	},
	keys = {
		{
			"<leader>aA",
			function()
				require("snacks").dashboard()
			end,
			desc = "Snacks Dashboard",
		},
		{
			"<leader>fn",
			function()
				require("snacks").notifier.show_history()
			end,
			desc = "Notification History",
		},
	},
}
