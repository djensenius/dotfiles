-- General editor settings

local opt = vim.opt
---@type {python_host_prog: string, loaded_netrw: number, loaded_netrwPlugin: number, mapleader: string}
vim.g = vim.g or {}

-- More efficient way to set multiple options
local options = {
	-- Display settings
	syntax = "on",
	showmode = false,
	number = true,
	ruler = true,
	showcmd = true,
	showcmdloc = "statusline",
	cmdheight = 1,
	laststatus = 2,
	scrolloff = 8,
	sidescroll = 1,
	sidescrolloff = 15,
	wrap = true,
	linebreak = true,
	showbreak = " ",
	cursorline = true,
	signcolumn = "yes", -- Always show sign column
	termguicolors = true, -- Enable 24-bit RGB color

	-- File handling
	writebackup = false,
	swapfile = false,
	autoread = true,
	undofile = true,
	undolevels = 1000,
	undoreload = 10000,
	updatetime = 100,

	-- Command line
	history = 1000,
	wildmenu = true,
	wildmode = "longest:full,full", -- Better command-line completion
	wildignore = "*.swp,*.bak,*.pyc,*.class", -- Ignore certain file types

	-- Mouse support
	mouse = "a",
	mousemoveevent = true,

	-- Visual feedback
	visualbell = true,
	list = true,
	listchars = {
		tab = "→ ",
		trail = "·",
		extends = "»",
		precedes = "«",
		nbsp = "␣",
	},

	-- Search settings
	smartcase = true,
	ignorecase = true,
	hlsearch = true,
	incsearch = true,

	-- Indentation
	tabstop = 2,
	shiftwidth = 2,
	expandtab = true,
	softtabstop = 2,
	autoindent = true,
	cindent = true,
	smarttab = true,
	breakindent = true, -- Preserve indentation in wrapped lines

	-- Split behavior
	splitbelow = true, -- New horizontal splits below
	splitright = true, -- New vertical splits right
}

-- Apply all options
for k, v in pairs(options) do
	opt[k] = v
end

-- Global variables
vim.g.python_host_prog = "/usr/bin/python3"

-- Filetype settings
vim.cmd([[
    filetype plugin on
    filetype indent on
]])

-- Create required directories if they don't exist
local data_dir = vim.fn.stdpath("data")
local backup_dir = data_dir .. "/backup"
local swap_dir = data_dir .. "/swap"
local undo_dir = data_dir .. "/undo"

for _, dir in ipairs({ backup_dir, swap_dir, undo_dir }) do
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
end

-- Set directory paths
vim.opt.backupdir = backup_dir
vim.opt.directory = swap_dir
vim.opt.undodir = undo_dir

-- Additional performance settings
vim.opt.redrawtime = 1500
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 10
vim.opt.updatetime = 100

-- Enable persistent undo
vim.opt.undofile = true

-- Disable default file explorer
vim.g.loaded_netrw = 1 -- Disable netrw
vim.g.loaded_netrwPlugin = 1 -- Disable netrw plugin

-- Better clipboard handling
---@diagnostic disable: undefined-field
vim.opt.clipboard:append("unnamedplus")
---@diagnostic enable: undefined-field

-- Status line configuration (if not using lualine)
vim.opt.statusline = [[%f %y%=%l,%c %P]]

-- Optional: Add autocmds for better experience
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ timeout = 200 })
	end,
})

-- Optional: Better buffer handling
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			vim.api.nvim_win_set_cursor(0, mark)
		end
	end,
})
