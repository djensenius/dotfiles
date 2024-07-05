return {
  "nvim-pack/nvim-spectre",
  cmd = "Spectre",
  event = "VeryLazy",
  keys = {
    {
      "<leader>St",
      function()
        require("spectre").toggle()
      end,
      desc = "Replace in files (Spectre)",
    },
    {
      "<leader>Sw",
      function()
        require("spectre").open_visual({select_word=true})
      end,
      desc = "Search current word"
    },
    {
      "<leader>Sf",
      function()
        require("spectre").open_file_search({select_word=true})
      end,
      desc = "Search current file"
    }
  },
}
