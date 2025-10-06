return {
	"folke/sidekick.nvim",
	event = "VeryLazy",
	opts = {
		-- add any options here
		cli = {
			mux = {
				backend = "tmux",
				enabled = true,
			},
			win = {
				keys = {
					-- This conflicts with Claude, but not Copilot which I'm using
					stopinsert = { "<esc><esc>", "stopinsert", mode = "t" },
				},
			},
		},
	},
	keys = {
		{
			"<tab>",
			function()
				-- if there is a next edit, jump to it, otherwise apply it if any
				if not require("sidekick").nes_jump_or_apply() then
					return "<Tab>" -- fallback to normal tab
				end
			end,
			expr = true,
			desc = "Goto/Apply Next Edit Suggestion",
		},
		{
			"<leader>coo",
			function()
				require("sidekick.cli").toggle()
			end,
			desc = "Sidekick Toggle CLI",
		},
		{
			"<leader>cos",
			function()
				require("sidekick.cli").select()
			end,
			-- Or to select only installed tools:
			desc = "Select CLI",
		},
		{
			"<leader>cot",
			function()
				require("sidekick.cli").send({ msg = "{this}" })
			end,
			mode = { "x", "n" },
			desc = "Send This",
		},
		{
			"<leader>cov",
			function()
				require("sidekick.cli").send({ msg = "{selection}" })
			end,
			mode = { "x" },
			desc = "Send Visual Selection",
		},
		{
			"<leader>cop",
			function()
				require("sidekick.cli").prompt()
			end,
			mode = { "n", "x" },
			desc = "Sidekick Select Prompt",
		},
		{
			"<c-.>",
			function()
				require("sidekick.cli").focus()
			end,
			mode = { "n", "x", "i", "t" },
			desc = "Sidekick Switch Focus",
		},
		-- Example of a keybinding to open Copilot directly
		{
			"<leader>coc",
			function()
				require("sidekick.cli").toggle({ name = "copilot", focus = true })
			end,
			desc = "Sidekick Toggle Claude",
		},
	},
}
