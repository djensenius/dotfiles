return {
  'nvim-neotest/neotest',
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'antoinemadec/FixCursorHold.nvim',
    'haydenmeade/neotest-jest'
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require('neotest-jest')({
          jestCommand = "npx jest",
          jestConfigFile = 'jest.config.js',
        }),
      },
      status = {
        virtual_text = false,
        signs = true,
      },
    })
    vim.cmd [[
      command! NeotestSummary lua require("neotest").summary.toggle()
      command! NeotestFile lua require("neotest").run.run(vim.fn.expand("%"))
      command! Neotest lua require("neotest").run.run(vim.fn.getcwd())
      command! NeotestNearest lua require("neotest").run.run()
      command! NeotestDebug lua require("neotest").run.run({ strategy = "dap" })
      command! NeotestAttach lua require("neotest").run.attach()
      command! NeotestOutput lua require("neotest").output.open()
    ]]
  end,
}
