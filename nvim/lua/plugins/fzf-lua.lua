return {
	"ibhagwan/fzf-lua",
	event = "VeryLazy",
	-- optional for icon support
	dependencies = { "nvim-tree/nvim-web-devicons", "elanmed/fzf-lua-frecency.nvim" },
	config = function()
		-- calling `setup` is optional for customization
		local frecency = require("fzf-lua-frecency")
		frecency.setup()
		require("fzf-lua").setup({ "default-title" })
		vim.keymap.set("n", "<c-G>", require("fzf-lua").live_grep, { desc = "Files" })
		vim.keymap.set("n", "<c-P>", function()
			require("fzf-lua").files({ line_query = true })
		end, { desc = "Files" })
		vim.keymap.set("n", "<leader>fzg", require("fzf-lua").live_grep, { desc = "Live grep" })
		vim.keymap.set("n", "<leader>fzf", function()
			require("fzf-lua").frecency({ cwd_only = true })
		end, { desc = "Frecency" })
		vim.keymap.set("n", "<leader>fzF", function()
			require("fzf-lua").files({ line_query = true })
		end, { desc = "Files" })
		vim.keymap.set("n", "<leader>fzr", require("fzf-lua").resume, { desc = "Resume" })
		vim.keymap.set("n", "<leader>fzo", require("fzf-lua").oldfiles, { desc = "Old files" })
		vim.keymap.set("n", "<leader>fzG", require("fzf-lua").git_status, { desc = "Git Status" })
		vim.keymap.set("n", "<leader>fzq", require("fzf-lua").quickfix, { desc = "Quickfix" })
		vim.keymap.set("n", "<leader>fzb", require("fzf-lua").buffers, { desc = "Buffers" })
		vim.keymap.set("n", "<leader>fzz", require("fzf-lua").global, { desc = "Global" })
		vim.keymap.set("n", "<leader>fzk", require("fzf-lua").keymaps, { desc = "Keymaps" })
		vim.keymap.set("n", "<leader>fzlr", require("fzf-lua").lsp_references, { desc = "References" })
		vim.keymap.set("n", "<leader>fzlD", require("fzf-lua").lsp_references, { desc = "Definitions" })
		vim.keymap.set("n", "<leader>fzlc", require("fzf-lua").lsp_declarations, { desc = "Declarations" })
		vim.keymap.set("n", "<leader>fzlt", require("fzf-lua").lsp_typedefs, { desc = "Type Definitions" })
		require("fzf-lua").register_ui_select()
	end,
}
