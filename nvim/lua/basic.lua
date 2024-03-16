-- luacheck: globals noshowmode linebreak on
vim.opt.syntax = on
vim.opt.nu = true
vim.opt.showmode = noshowmode
vim.opt.showcmdloc = "statusline"
vim.opt.ruler = true
vim.opt.showcmd = true
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.laststatus = 2
vim.opt.autoread = true
vim.opt.history = 1000
vim.opt.scrolloff = 8
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 15
vim.opt.wrap = linebreak
vim.opt.showbreak = " "
vim.opt.visualbell = true
vim.opt.wildmenu = true
vim.opt.mouse:append("a")
vim.opt.statusline:append("%f")
vim.opt.cursorline = true

-- Tab/indent configuration
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.cindent = true
vim.opt.smarttab = true

-- Search configuration
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Undo file settings
vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000
vim.opt.updatetime = 100
vim.g.python_host_prog = "/usr/bin/python3"
