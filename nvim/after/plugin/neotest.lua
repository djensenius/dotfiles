require("neotest").setup({
  adapters = {
    require('neotest-jest')({
      jestCommand = "npm test --"
    }),
    require('neotest-rspec'),
    require('neotest-go')
  }
})

