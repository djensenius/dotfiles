-- Linting
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require('lint').linters_by_ft = {
      ruby = {'rubocop',}
    }
    vim.api.nvim_create_autocmd({ "BufWritePost, BufRead,InsertLeave,TextChanged" }, {
      pattern='*.md,*.txt,*.rb,*.lua',
      callback = function()
        require("lint").try_lint()
      end,
    })
  end,
}
