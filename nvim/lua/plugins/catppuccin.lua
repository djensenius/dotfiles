return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = false,
      background = {
        light = "latte",
        dark = "mocha",
      },
      compile = {
        enabled = true,
      },
      dim_inactive = {
        enabled = true,
      },
      integrations = {
        treesitter = true,
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
        },
        gitsigns = true,
        lsp_trouble = true,
        dap = {
          enabled = true,
          enable_ui = true,
        },
        neotree = {
          enabled = true,
          show_root = true,
          transparent_panel = false,
        },
        which_key = true,
        indent_blankline = {
          enabled = true,
          colored_indent_levels = false,
        },
      },
    })
    vim.cmd([[colorscheme catppuccin]])
  end,
}
