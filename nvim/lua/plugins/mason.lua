return {
  "williamboman/mason-lspconfig.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    {
      "williamboman/mason.nvim",
      config = function()
        require("mason").setup()
        local tools = {
          "css-lsp",
          "eslint-lsp",
          "eslint_d",
          "firefox-debug-adapter",
          "html-lsp",
          "js-debug-adapter",
          "json-lsp",
          "lua-language-server",
          "node-debug2-adapter",
          "prettierd",
          "shellcheck",
          "stylelint-lsp",
          "stylua",
          "tailwindcss-language-server",
          "typescript-language-server",
          "yaml-language-server",
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
      }
    })
  end,
}
