return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	config = function()
		local wk = require("which-key")
		wk.register({
			f = {
				name = "Finding",
			},
			["<space>"] = {
				name = "Diagnostics",
			},
			_ = {
				name = "Comments",
			},
			g = {
				name = "Git",
			},
			h = {
				name = "Git signs",
			},
			c = {
				name = "Path & Copilot Chat",
				c = {
					name = "Copilot Chat",
				},
			},
			k = "which_key_ignore",
			["<C-K>"] = "which_key_ignore",
			n = "Line numbering",
			p = "which_key_ignore",
			P = "which_key_ignore",
			r = "Relative line numbering",
			s = {
				name = "Session, Source, and Split",
			},
      S = {
        name = "Search & Replace",
      },
			t = {
				name = "Testing & Tree",
			},
		}, { prefix = "<leader>" })
	end,
}
