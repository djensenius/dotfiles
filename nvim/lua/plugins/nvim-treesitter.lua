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
        "rust",
        "go",
        "lua",
        "bash",
        "css",
        "dockerfile",
        "fish",
        "graphql",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "python",
        "ruby",
        "scss",
        "tsx",
        "typescript",
        "vim",
        "supercollider"
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
