if vim.fn.isdirectory(vim.fn.expand("~/Vaults")) == 1 then
	return {
		"epwalsh/obsidian.nvim",
		version = "*", -- recommended, use latest release instead of latest commit
		lazy = true,
		ft = "markdown",
		event = {
			"BufReadPre " .. vim.fn.expand("~") .. "/Vaults/Death in Space/*.md",
			"BufNewFile " .. vim.fn.expand("~") .. "/Vaults/Death in Space/*.md",
		},
		dependencies = {
			-- Required.
			"nvim-lua/plenary.nvim",
			-- see below for full list of optional dependencies 👇
		},
		opts = {
			workspaces = {
				{
					name = "Death in Space",
					path = "~/Vaults/Death in Space",
				},
			},
			-- Disable obsidian UI to avoid conflicts with render-markdown.nvim
			ui = {
				enable = false,
			},
			-- see below for full list of options 👇
		},
	}
else
	return {}
end
