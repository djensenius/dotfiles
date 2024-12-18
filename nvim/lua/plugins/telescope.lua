-- luacheck: max_line_length 140
return {
	"nvim-telescope/telescope.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-lua/popup.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
      build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release"
		},
	},
	config = function()
		require("telescope").setup({
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown({}),
				},
			},
		})
		vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files)
		vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep)
		vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers)
		vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags)
		vim.keymap.set("n", "<leader>fn", require('telescope').extensions.notify.notify)
		vim.keymap.set("n", "<leader>fd", function()
      require("telescope.builtin").lsp_definitions({ jump_type = "never" })
    end)
		vim.keymap.set("n", "<leader>fr", function()
      require("telescope.builtin").lsp_references()
    end)
		require("telescope").load_extension("fzf")
		require("telescope").load_extension("ui-select")
	end,
}
