set runtimepath^=~/.vim runtimepath+=~/.vim/after
set shell=/bin/zsh
let g:custom_path = '~/.config/nvim/'
let &packpath = &runtimepath
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set termguicolors
source $HOME/.config/nvim/plugins.vim
source $HOME/.config/nvim/theme.vim
source $HOME/.config/nvim/basic.vim
source $HOME/.config/nvim/keys.vim
source $HOME/.config/nvim/plugins/expand-region.vim
source $HOME/.config/nvim/plugins/fugitive.vim
source $HOME/.config/nvim/plugins/gitgutter.vim
source $HOME/.config/nvim/plugins/gitmessenger.vim
source $HOME/.config/nvim/plugins/indentline.vim
source $HOME/.config/nvim/plugins/javascript.vim
source $HOME/.config/nvim/plugins/tabular.vim
source $HOME/.config/nvim/plugins/tagbar.vim
source $HOME/.config/nvim/plugins/vim-signature.vim
source $HOME/.config/nvim/plugins/vimux.vim
source $HOME/.config/nvim/plugins/indent-guides.vim
source $HOME/.config/nvim/plugins/start-screen.vim
source $HOME/.config/nvim/lua/vim-ultest.vim
source $HOME/.config/nvim/plugins/telescope.vim
luafile $HOME/.config/nvim/lua/plug-colorizer.lua
luafile $HOME/.config/nvim/lua/treesitter.lua
luafile $HOME/.config/nvim/lua/gitsigns.lua
luafile $HOME/.config/nvim/lua/coq.lua
luafile $HOME/.config/nvim/lua/lspconfig.lua
luafile $HOME/.config/nvim/lua/tabline.lua
luafile $HOME/.config/nvim/lua/whichkey.lua
luafile $HOME/.config/nvim/lua/nvim-tree.lua
luafile $HOME/.config/nvim/lua/lualine.lua
