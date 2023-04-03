return  {
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
        "python",
        "ruby",
        "scss",
        "tsx",
        "typescript",
        "vim",
        "supercollider"
      },
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
