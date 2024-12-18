return {
  "ibhagwan/fzf-lua",
  event = "VeryLazy",
  -- optional for icon support
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    -- calling `setup` is optional for customization
    require("fzf-lua").setup({})
  end,
  vim.keymap.set("n", "<leader>fzg", ":FzfLua live_grep<CR>", { desc = "Live grep" }),
  vim.keymap.set("n", "<leader>fzf", ":FzfLua files<CR>", { desc = "Files" }),
  vim.keymap.set("n", "<leader>fzr", ":FzfLua resume<CR>", { desc = "Resume" }),
  vim.keymap.set("n", "<leader>fzg", ":FzfLua git_status<CR>", { desc = "Git Status" }),
  vim.keymap.set("n", "<leader>fzq", ":FzfLua quickfix<CR>", { desc = "Quickfix" }),
  vim.keymap.set("n", "<leader>fzlr", ":FzfLua lsp_references<CR>", { desc = "References" }),
  vim.keymap.set("n", "<leader>fzlD", ":FzfLua lsp_definitions<CR>", { desc = "Definitions" }),
  vim.keymap.set("n", "<leader>fzlc", ":FzfLua lsp_declarations<CR>", { desc = "Declarations" }),
  vim.keymap.set("n", "<leader>fzlt", ":FzfLua lsp_typedefs<CR>", { desc = "Type Definitions" }),
}
