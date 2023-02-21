return {
  "rcarriga/nvim-notify",
  config = function()
    require("notify").setup {
      stages = 'fade_in_slide_out',
      background_colour = 'FloatShadow',
      timeout = 2000,
    }
    vim.notify = require('notify')
  end,
}
