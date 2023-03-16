return {
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  dependiencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim"
  },
  config = function()
    require("chatgpt").setup({
      keymaps = {
        open = "<leader>cg",
        close = "<Esc>",
        send = "<CR>",
        submit = "<C-s>",
      },
    })
  end
}
