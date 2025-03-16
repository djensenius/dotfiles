return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "main",
		dependencies = {
			{ "github/copilot.vim" }, -- or github/copilot.vim
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
    build = "make tiktoken",
		event = "VeryLazy",
		config = function()
			require("CopilotChat").setup({
				auto_insert_mode = true,
        chat_autocomplete = true,
				show_help = false,
				show_folds = false,
				question_header = "  David ",
				answer_header = "  Copilot ",
			})
		end,
		keys = {
			{ "<leader>cce", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
			{ "<leader>ccr", "<cmd>CopilotChatReview<cr>", desc = "CopilotChat - Review code" },
			{ "<leader>ccf", "<cmd>CopilotChatFix<cr>", desc = "CopilotChat - Fix" },
			{ "<leader>cco", "<cmd>CopilotChatOptimize<cr>", desc = "CopilotChat - Optimize" },
			{ "<leader>ccd", "<cmd>CopilotChatDocs<cr>", desc = "CopilotChat - Add Documentation" },
			{ "<leader>cct", "<cmd>CopilotChatTests<cr>", desc = "CopilotChat - Generate tests" },
			{ "<leader>ccD", "<cmd>CopilotChatFixDiagnostic<cr>", desc = "CopilotChat - diagnostic issue in file" },
			{ "<leader>ccc", "<cmd>CopilotChatCommit<cr>", desc = "CopilotChat - Commit message" },
			{ "<leader>ccs", "<cmd>CopilotChatCommitStaged<cr>", desc = "CopilotChat - Commit message" },
			{ "<leader>ccT", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Copilot Chat" },
			{ "<leader>ccm", "<cmd>CopilotChatModel<cr>", desc = "Copilot Chat Models" },
			{
				"<leader>cch",
				function()
					local actions = require("CopilotChat.actions")
					require("CopilotChat.integrations.telescope").pick(actions.help_actions())
				end,
				desc = "CopilotChat - Help actions",
			},
			-- Show prompts actions with telescope
			{
				"<leader>ccp",
				function()
					local actions = require("CopilotChat.actions")
					require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
				end,
				desc = "CopilotChat - Prompt actions",
			},
		},
	},
}
