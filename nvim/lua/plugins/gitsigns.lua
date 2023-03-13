-- luacheck: ignore 211 212
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {},
  config = function()
    require('gitsigns').setup {
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns
      end
    }
  end,
}
