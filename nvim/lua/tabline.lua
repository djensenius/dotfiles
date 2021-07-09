Tabline = require'luatab'.tabline
vim.cmd[[ set tabline=%!luaeval('Tabline()') ]]
