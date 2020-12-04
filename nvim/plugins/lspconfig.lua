local on_attach = function(client)
  require('completion').on_attach(client)

  local options = {
    noremap = true,
    silent = true
  }

  vim.api.nvim_set_keymap('n', '<c-]>', '<cmd>lua vim.lsp.buf.definition()<CR>', options)
  vim.api.nvim_set_keymap('n', 'df', '<cmd>lua vim.lsp.buf.hover()<CR>', options)
  vim.api.nvim_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.implementation()<CR>', options)
  vim.api.nvim_set_keymap('n', '1gD', '<cmd>lua vim.lsp.buf.type_definition()<CR>', options)
  vim.api.nvim_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', options)
  vim.api.nvim_set_keymap('n', 'g0', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', options)
  vim.api.nvim_set_keymap('n', 'gW', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', options)
  vim.api.nvim_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.declaration()<CR>', options)

  vim.api.nvim_command([[setlocal omnifunc=v:lua.vim.lsp.omnifunc]])
  vim.api.nvim_command([[autocmd CursorHold  * lua vim.lsp.diagnostic.show_line_diagnostics({ show_header = false })]])
end


require'lspconfig'.gopls.setup{}

require'lspconfig'.diagnosticls.setup {
  filetypes = {"javascript", "typescript", "javascriptreact", "typescriptreact", "javascript.jsx", "typescript.tsx"},
  init_options = {
    filetypes = {
      javascript = "eslint",
      javascriptreact = "eslint",
      typescript = "eslint",
      typescriptreact = "eslint",
      ["typescript.tsx"] = "eslint",
      ["javascript.jsx"] = "eslint"
    },
    linters = {
      eslint = {
        command = "./node_modules/.bin/eslint",
        rootPatterns = {".git"},
        debounce = 100,
        args = {
          "--stdin",
          "--stdin-filename",
          "%filepath",
          "--format",
          "json"
        },
        sourceName = "eslint",
        parseJson = {
          errorsRoot = "[0].messages",
          line = "line",
          column = "column",
          endLine = "endLine",
          endColumn = "endColumn",
          message = "[eslint] ${message} [${ruleId}]",
          security = "severity"
        },
        securities = {
          [2] = "error",
          [1] = "warning"
        }
      }
    }
  }
}
require'lspconfig'.tsserver.setup({
  on_attach = on_attach
})

