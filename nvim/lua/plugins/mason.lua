return {
  "williamboman/mason-lspconfig.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    {
      "williamboman/mason.nvim",
      config = function()
        require("mason").setup()
        local tools = {
          "rubocop",
          "css-lsp",
          "dockerfile-language-server",
          "eslint-lsp",
          "eslint_d",
          "firefox-debug-adapter",
          "gofumpt",
          "golangci-lint-langserver",
          "gotestsum",
          "html-lsp",
          "js-debug-adapter",
          "json-lsp",
          "lua-language-server",
          "node-debug2-adapter",
          "prettierd",
          "rust-analyzer",
          "shellcheck",
          "stylelint-lsp",
          "stylua",
          "tailwindcss-language-server",
          "typescript-language-server",
          "yaml-language-server",
          "solargraph",
          "sorbet",
          "ruby-lsp",
        }
        local function check()
          local mr = require("mason-registry")
	        for _, tool in ipairs(tools) do
		        local p = mr.get_package(tool)
		        if not p:is_installed() then
			        p:install()
		        end
	        end
        end
       	check()
      end,
    },
    "neovim/nvim-lspconfig"
  },
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = {
        "tsserver",
        "gopls",
        "graphql",
        "html",
        "marksman"
      }
    })
  end,
}
