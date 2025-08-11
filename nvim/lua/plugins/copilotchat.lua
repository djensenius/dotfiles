return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "main",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim" },
		},
		build = "make tiktoken",
		event = "VeryLazy",
		config = function()
			require("CopilotChat").setup({
				highlight_headers = false,
				separator = "---",
				error_header = "> [!ERROR] Error",
				auto_insert_mode = true,
				chat_autocomplete = true,
				show_help = false,
				show_folds = false,
				headers = {
					user = "##   David: ",
					assistant = "##   Copilot: ",
					tool = "## 🔧 Tool: ",
				},
				prompts = {
					Explain = "Explain how it works.",
					Tests = "Generate unit tests for the selected code.",
					Review = "Review the code and suggest improvements.",
					Refactor = "Refactor the code for clarity.",
					Docs = "Add documentation for the selected code.",
				},
			})
		end,
		keys = {
			{ "<leader>cct", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Copilot Chat" },
			{ "<leader>ccm", "<cmd>CopilotChatModel<cr>", desc = "Copilot Chat Models" },
			{ "<leader>ccp", "<cmd>CopilotChatPrompts<cr>", desc = "CopilotChat - Prompt actions" },
			{
				"<leader>ccq",
				function()
					local input = vim.fn.input("Quick Chat: ")
					if input ~= "" then
						require("CopilotChat").ask(input, {
							selection = require("CopilotChat.select").buffer,
						})
					end
				end,
				desc = "CopilotChat - Quick chat",
			},
		},
	},
}
