-- luacheck: globals vim
vim.opt.termguicolors = true
require("basic")
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.runtimepath:prepend(lazypath)
vim.g.mapleader = ","
require("lazy").setup({
	spec = {
		-- import your plugins
		{ import = "plugins" },
	},
	-- automatically check for plugin updates
	checker = { enabled = true },
})
vim.opt.shell = "/bin/zsh"
require("keys")
