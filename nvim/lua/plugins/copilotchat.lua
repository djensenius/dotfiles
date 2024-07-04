--[[
--
-- pip install python-dotenv requests pynvim==0.5.0 prompt-toolkit
-- https://github.com/jellydn/CopilotChat.nvim
-- ]]

return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "canary",
		dependencies = {
			{ "github/copilot.vim" }, -- or github/copilot.vim
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		event = "VeryLazy",
		config = function()
      require("CopilotChat.integrations.cmp").setup()
        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = "copilot-chat",
            callback = function()
                vim.opt_local.relativenumber = false
                vim.opt_local.number = false
            end,
        })
      require("CopilotChat").setup({
            auto_insert_mode = true,
            show_help = false,
            show_folds = false,
            question_header = "  David ",
            answer_header = "  Copilot ",
            window = {
                layout = "float",
                width = 0.6,
                height = 0.7,
                border = "rounded",
            },
            mappings = {
                close = {
                    normal = "q",
                    insert = "C-q",
                },
            },
            selection = function(source)
                local select = require("CopilotChat.select")
                return select.visual(source) or select.buffer(source)
            end,
        })
		end,
		keys = {
			{ "<leader>cce", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
			{ "<leader>ccr", "<cmd>CopilotChatReview<cr>", desc = "CopilotChat - Review code" },
			{ "<leader>ccf", "<cmd>CopilotChatFix<cr>", desc = "CopilotChat - Fix" },
			{ "<leader>cco", "<cmd>CopilotChatOptimize<cr>", desc = "CopilotChat - Optimize" },
			{ "<leader>ccd", "<cmd>CopilotChatDocs<cr>", desc = "CopilotChat - Add Documentation" },
			{ "<leader>cct", "<cmd>CopilotChatTests<cr>", desc = "CopilotChat - Generate tests" },
			{ "<leader>ccd", "<cmd>CopilotChatFixDiagnostic<cr>", desc = "CopilotChat - diagnostic issue in file" },
			{ "<leader>ccc", "<cmd>CopilotChatCommit<cr>", desc = "CopilotChat - Commit message" },
			{ "<leader>ccs", "<cmd>CopilotChatCommitStaged<cr>", desc = "CopilotChat - Commit message" },
			{ "<leader>ccT", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Copilot Chat" },
		},
	},
}
