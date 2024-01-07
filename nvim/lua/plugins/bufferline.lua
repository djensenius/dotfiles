return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("bufferline").setup({
      options = {
        offsets = {
          {
            filetype = "neo-tree",
            text = "File explorer",
            highlight = "Directory",
            separator = true, -- use a "true" to enable the default, or set your own character
          },
        },
        numbers = function(opts)
          return string.format("%s", opts.raise(opts.id))
        end,
        hover = {
          enabled = true,
          delay = 200,
          reveal = { "close" },
        },
        mode = "tabs",
        diagnostics = "nvim_lsp",
        separator_style = "slant",
      },
    })
  end,
}
