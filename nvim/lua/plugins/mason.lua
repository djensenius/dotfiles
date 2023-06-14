return {
  "williamboman/mason-lspconfig.nvim",
  build = ":MasonUpdate",
  dependencies = {
    {
      "williamboman/mason.nvim",
      config = function()
        require("mason").setup()
        local tools = {
          "eslint-lsp",
          "eslint_d",
          "luacheck",
          "lua-language-server",
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
        "lua_ls",
      }
    })
  end,
}
