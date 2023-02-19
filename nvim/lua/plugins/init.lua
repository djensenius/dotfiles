return {
  { "catppuccin/nvim", name = "catppuccin" },
  { "folke/trouble.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "kyazdani42/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "RishabhRD/nvim-lsputils", dependencies = { "RishabhRD/popfix" } },
  { "onsails/lspkind-nvim" },
  { "lewis6991/gitsigns.nvim" },
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "alvarosevilla95/luatab.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "windwp/nvim-autopairs" },
  { "norcalli/nvim-colorizer.lua" },
  { "mfussenegger/nvim-lint" },
  { "neovim/nvim-lspconfig" },
  { "nvim-treesitter/nvim-treesitter" },
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-lua/popup.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-web-devicons",
    },
  },
  { "folke/which-key.nvim" },
  {
    "benmills/vimux",
    config = function()
      vim.cmd("source $HOME/.config/nvim/plugins/vimux.vim")
    end,
  },
  { "danro/rename.vim" },
  { "tpope/vim-endwise" },
  { "tpope/vim-repeat" },
  { "supercollider/scvim" },
  { "lukas-reineke/indent-blankline.nvim" },
  { "folke/lsp-colors.nvim" },
  { "williamboman/mason.nvim" },
  { "simrat39/rust-tools.nvim", dependencies = { "neovim/nvim-lspconfig" } },
  { "nvim-lua/plenary.nvim" },
  {
    "mhinz/vim-startify",
    config = function()
      vim.cmd("source $HOME/.config/nvim/plugins/start-screen.vim")
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-lua/popup.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build" },
    },
    config = function()
      vim.cmd("source $HOME/.config/nvim/plugins/telescope.vim")
    end,
  },
  { "antoinemadec/FixCursorHold.nvim" },
  { "kosayoda/nvim-lightbulb" },
  { "ray-x/guihua.lua", build = "cd lua/fzy && make" },
  { "ray-x/navigator.lua" },
  { "github/copilot.vim" },
  { "machakann/vim-sandwich" },
  { "ojroques/vim-oscyank" },
  {
    "tpope/vim-obsession",
    config = function()
      vim.cmd("source $HOME/.config/nvim/plugins/obsession.vim")
    end,
  },
}
