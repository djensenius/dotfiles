return {
  "neovim/nvim-lspconfig",
  dependencies = { "nvim-tree/nvim-web-devicons", "folke/trouble.nvim", "hrsh7th/cmp-nvim-lsp" },
  event = "VeryLazy",

  config = function()
    require 'lspconfig'

    -- Prepare completion
    local on_attach = function(client, bufnr)
      local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
      end

      -- Mappings.
      local opts = {noremap = true, silent = true}
      buf_set_keymap('n', '<leader><space>D', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
      buf_set_keymap('n', '<leader><space>f', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
      buf_set_keymap('n', '<leader><space>h', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
      buf_set_keymap('n', '<leader><space>i', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
      buf_set_keymap('n', '<leader><space>S', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
      buf_set_keymap('n', '<leader><space>R', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
      buf_set_keymap('n', '<leader><space>r', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
      buf_set_keymap('n', '<leader><space>d', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
      buf_set_keymap('n', '<leader><space>i', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
      buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
      buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)

      -- Set some keybinds conditional on server capabilities
      if client.server_capabilities.document_formatting then
        buf_set_keymap("n", "<space>=", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
      elseif client.server_capabilities.document_range_formatting then
        buf_set_keymap("n", "<space>=", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
      end
    end

    local util = require 'lspconfig/util'
    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    require('lspconfig')['tsserver'].setup{
      on_attach = on_attach,
      root_dir = util.root_pattern("tsconfig.json"),
      capabilities = capabilities,
    }

    require('lspconfig')['sorbet'].setup{
      on_attach = on_attach,
      capabilities = capabilities,
    }

    --[[
    require('lspconfig')['solargraph'].setup{
      on_attach = on_attach,
      flags = lsp_flags,
    }
    --]]

    require('lspconfig')['eslint'].setup({
      on_attach=on_attach,
      root_dir = util.root_pattern("package.json"),
      capabilities = capabilities,
    })

    require('lspconfig')['lua_ls'].setup{
      settings = {
        Lua = {
          runtime = {
            -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
            version = 'LuaJIT',
          },
          diagnostics = {
            globals = {'vim'},
          },
          workspace = {
            -- Make the server aware of Neovim runtime files
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
      on_attach = on_attach,
      capabilities = capabilities,
    }

    local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl= hl, numhl = hl })
    end

    require("trouble").setup({
      signs = {
        -- icons / text used for a diagnostic
        error = "",
        warning = "",
        hint = "",
        information = "",
        other = ""
      },
    })
  end,
}
