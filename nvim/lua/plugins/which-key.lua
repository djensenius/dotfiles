return {
  "folke/which-key.nvim",
  config = function()
    local wk = require("which-key")
    wk.register({
      f = {
        name = "Finding"
      },
      ["<space>"] = {
        name = "Diagnostics"
      },
      _ = {
        name = "Comments"
      },
      g = {
        name = "Git"
      },
      h = {
        name = "Git signs"
      },
      k = "which_key_ignore",
      ["<C-K>"] = "which_key_ignore",
      n = "Line numbering",
      p = "which_key_ignore",
      P = "which_key_ignore",
      r = "Relative line numbering",
      s = {
        name = "Split / Source"
      },
      t = {
        name = "Testing"
      }
    }, { prefix = "<leader>" })
  end,
}
