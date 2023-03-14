-- Move around splits with <c-hjkl>
vim.keymap.set('n', '<C-k>', '<C-w><Up>')
vim.keymap.set('n', '<C-j>', '<C-w><Down>')
vim.keymap.set('n', '<C-l>', '<C-w><Right>')
vim.keymap.set('n', '<C-h>', '<C-w><Left>')

vim.keymap.set('i', '<C-k>', '<Up>')
vim.keymap.set('i', '<C-j>', '<Down>')
vim.keymap.set('i', '<C-l>', '<Right>')
vim.keymap.set('i', '<C-h>', '<Left>')

-- Buffer and tab operations with <s-hjkl>
vim.keymap.set('n', '<s-h>', ':bprevious<cr>')
vim.keymap.set('n', '<s-l>', ':bnext<cr>')
vim.keymap.set('n', '<s-j>', ':tabnext<cr>')
vim.keymap.set('n', '<s-k>', ':tabprev<cr>')
vim.keymap.set('n', '<s-t>', ':tabnew<cr>')

-- Copilot
vim.keymap.set('n', '<leader>cp', ':Copilot panel<cr>')

vim.keymap.set('n', '<leader>no', ':set nonu<cr>')
vim.keymap.set('n', '<leader>nu', ':set nu<cr>')
vim.keymap.set('n', '<leader>rn', ':set rnu<cr>')
vim.keymap.set('n', '<leader>nrn', ':set nornu<cr>')
vim.keymap.set('n', '<leader>nh', ':nohls<cr>')
vim.keymap.set('n', '<leader>so', ':source ~/.config/nvim/init.lua<cr>')
vim.keymap.set('n', '<leader>tt', ':TroubleToggle<cr>')

-- System clipboard copy/paste
vim.keymap.set('v', '<leader>y', '"+y')
vim.keymap.set('v', '<leader>d', '"+d')
vim.keymap.set('n', '<leader>p', '"+p')
vim.keymap.set('n', '<leader>P', '"+P')

-- Split
vim.keymap.set('', '<leader>sp', ':split<cr>')
vim.keymap.set('', '<leader>sv', ':vsplit<cr>')
