return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	config = function()
		local wk = require("which-key")
		wk.register({
			f = {
				name = "Finding & Format",
        b = "Buffers",
        f = "Files",
        g = "Grep",
        h = "Help",
        n = "Notify",
        m = {
          name = "Format",
          t = "Format [LSP]",
        },
			},
			["<space>"] = {
				name = "Diagnostics",
        P = "Rename",
			},
			_ = {
				name = "Comments",
			},
			g = {
				name = "Git",
        b = "Toggle Line Blame",
        c = "Commit",
        h = "Line highlight",
        j = "Next hunk",
        k = "Previous hunk",
        l = "Line highlight",
        p = "Preview hunk",
        r = "Reset hunk",
        R = "Reset buffer",
        s = "Stage hunk",
        S = "Stage buffer",
        U = "Reset buffir index",
        u = "Undo stage hunk",
			},
			h = {
				name = "Git signs",
			},
			c = {
				name = "Path & Copilot Chat",
				c = "Copilot Chat",
        f = "Copy full path",
        p = "Copilot Panel",
        r = "Copy relative path",
			},
			k = "which_key_ignore",
			["<C-K>"] = "which_key_ignore",
			n =  {
        name = "Line numbering",
        h = "No highlight",
        o = "No line numbers",
        u = "Line numvers",
        r = {
          name = "Relative line numbering",
          r = "No relative line numbering",
        }
      },
			p = "which_key_ignore",
			P = "which_key_ignore",
			r = {
        name = "Relative line numbering",
        n = "Relative line numbering",
      },
			s = "Session, Source, and Split",
      S = "Search & Replace",
			t = {
				name = "Testing & Tree",
        f = "Test file",
        l = "Test last",
        n = "Test nearest",
        s = "Test suite",
        t = "Trouble",
        v = "Test visit",
			},
		}, { prefix = "<leader>" })
	end,
}
