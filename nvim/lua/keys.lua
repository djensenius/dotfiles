-- Move around splits with <c-hjkl>
-- vim.keymap.set("n", "<C-k>", "<C-w><Up>")
-- vim.keymap.set("n", "<C-j>", "<C-w><Down>")
-- vim.keymap.set("n", "<C-l>", "<C-w><Right>")
-- vim.keymap.set("n", "<C-h>", "<C-w><Left>")

vim.keymap.set("i", "<C-k>", "<Up>")
vim.keymap.set("i", "<C-j>", "<Down>")
vim.keymap.set("i", "<C-l>", "<Right>")
vim.keymap.set("i", "<C-h>", "<Left>")

-- Buffer and tab operations with <s-hjkl>
vim.keymap.set("n", "<s-h>", ":bprevious<cr>")
vim.keymap.set("n", "<s-l>", ":bnext<cr>")
vim.keymap.set("n", "<s-j>", ":tabnext<cr>")
vim.keymap.set("n", "<s-k>", ":tabprev<cr>")
vim.keymap.set("n", "<s-t>", ":tabnew<cr>")

-- Copilot
vim.keymap.set("n", "<leader>cp", ":Copilot panel<cr>")

vim.keymap.set("n", "<leader>no", ":set nonu<cr>")
vim.keymap.set("n", "<leader>nu", ":set nu<cr>")
vim.keymap.set("n", "<leader>rn", ":set rnu<cr>")
vim.keymap.set("n", "<leader>nrn", ":set nornu<cr>")
vim.keymap.set("n", "<leader>nh", ":nohls<cr>")

-- Copy and paste

if vim.fn.has("macunix") == 1 then
	vim.opt.clipboard = "unnamedplus"
end
vim.cmd("vnoremap <silent> y y`]")
vim.cmd("vnoremap <silent> p p`]")
vim.cmd("nnoremap <silent> p p`]")
vim.cmd('nnoremap <silent> x "_x')
vim.keymap.set("v", "<Leader>y", '"+y')
vim.keymap.set("v", "<Leader>d", '"+d')
vim.keymap.set("n", "<Leader>p", '"+p')
vim.keymap.set("n", "<Leader>P", '"+P')

-- Save and quit
vim.keymap.set("n", "<leader>w", ":w<CR>", { silent = true })
vim.keymap.set("n", "<leader>q", ":q<CR>", { silent = true })

-- Split
vim.keymap.set("", "<leader>sp", ":split<cr>")
vim.keymap.set("", "<leader>sh", ":split<cr>")
vim.keymap.set("", "<leader>sv", ":vsplit<cr>")

-- File operations
vim.api.nvim_create_user_command("CopyFullPath", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.cmd("OSCYankRegister +")
end, {})
vim.keymap.set("n", "<leader>cf", ":CopyFullPath<cr>")

vim.api.nvim_create_user_command("CopyRelativePath", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	vim.cmd("OSCYankRegister +")
end, {})
vim.keymap.set("n", "<leader>cr", ":CopyRelativePath<cr>")
