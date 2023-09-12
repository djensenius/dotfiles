return {
  "jose-elias-alvarez/null-ls.nvim",
  event = "VeryLazy",
  config = function()
    local null_ls = require "null-ls"
    -- local diagnostics = null_ls.builtins.diagnostics
    local conditional = function(fn)
      local utils = require("null-ls.utils").make_conditional_utils()
      return fn(utils)
    end


    -- need to import first
    null_ls.setup({
      debug = false,
      sources = {
        null_ls.builtins.formatting.prettierd.with({
          env = {
            string.format('PRETTIERD_DEFAULT_CONFIG=%s', vim.fn.expand("~/.config/prettierrc.json")),
          },
        }),
        conditional(function(utils)
          return utils.root_has_file("Gemfile")
            and null_ls.builtins.formatting.rubocop.with({})
          or null_ls.builtins.formatting.rubocop
        end),

        -- Same as above, but with diagnostics.rubocop to make sure we use the proper rubocop version for the project
        conditional(function(utils)
          return utils.root_has_file("Gemfile")
           and null_ls.builtins.diagnostics.rubocop.with({})
          or null_ls.builtins.diagnostics.rubocop
      end),
      },
      on_attach = function(client, bufnr)
        -- local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })
        -- local event = "BufWritePre" -- or "BufWritePost"
        -- local async = event == "BufWritePost"
        if client.supports_method("textDocument/formatting") then
          vim.keymap.set("n", "<Leader>fmt", function()
            vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
          end, { buffer = bufnr, desc = "[lsp] format" })

          -- format on save
          --[[
          vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
          vim.api.nvim_create_autocmd(event, {
            buffer = bufnr,
            group = group,
            callback = function()
              vim.lsp.buf.format({ bufnr = bufnr, async = async })
            end,
            desc = "[lsp] format on save",
          })
          --]]
        end

        --[[
        if client.supports_method("textDocument/rangeFormatting") then
          vim.keymap.set("x", "<Leader>fmt", function()
            vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
          end, { buffer = bufnr, desc = "[lsp] format" })
        end
        --]]
      end,
    })
  end
}
-- Linting
