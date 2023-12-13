return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter.configs").setup {
      highlight = { enable = true },
      indent = { enable = true, disable = { "python" } },
      context_commentstring = { enable = true, enable_autocmd = false },
      ensure_installed = {
        "bash",
        "css",
        "dockerfile",
        "fish",
        "go",
        "graphql",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "python",
        "ruby",
        "rust",
        "scss",
        "supercollider",
        "tsx",
        "typescript",
        "vim"
      },
      auto_install = true,
      sync_install = false,
      ignore_install = {},
      modules = {},
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "gnn",
          scope_incremental = "gnc",
          node_decremental = "gnd",
        },
      },
    }
  end,
}
