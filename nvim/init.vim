set runtimepath^=~/.vim runtimepath+=~/.vim/after
let g:custom_path = '~/.config/nvim/'
let &packpath = &runtimepath
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set termguicolors
source $HOME/.config/nvim/plugins.vim
source $HOME/.config/nvim/theme.vim
source $HOME/.config/nvim/basic.vim
source $HOME/.config/nvim/keys.vim
source $HOME/.config/nvim/plugins/ag.vim
" source $HOME/.config/nvim/plugins/ale.vim
source $HOME/.config/nvim/plugins/elm-vim.vim
source $HOME/.config/nvim/plugins/expand-region.vim
source $HOME/.config/nvim/plugins/fugitive.vim
" source $HOME/.config/nvim/plugins/fzf.vim
source $HOME/.config/nvim/plugins/gitgutter.vim
source $HOME/.config/nvim/plugins/gitmessenger.vim
source $HOME/.config/nvim/plugins/indentline.vim
source $HOME/.config/nvim/plugins/javascript.vim
" source $HOME/.config/nvim/plugins/jsx.vim
" source $HOME/.config/nvim/plugins/neocomplcache.vim
source $HOME/.config/nvim/plugins/supertab.vim
source $HOME/.config/nvim/plugins/tabular.vim
source $HOME/.config/nvim/plugins/tagbar.vim
source $HOME/.config/nvim/plugins/vim-signature.vim
source $HOME/.config/nvim/plugins/vimspector.vim
source $HOME/.config/nvim/plugins/vimux.vim
source $HOME/.config/nvim/plugins/indent-guides.vim
source $HOME/.config/nvim/plugins/start-screen.vim
source $HOME/.config/nvim/plugins/telescope.vim
source $HOME/.config/nvim/lua/vim-ultest.vim
luafile $HOME/.config/nvim/lua/plug-colorizer.lua
luafile $HOME/.config/nvim/lua/prettier.lua
luafile $HOME/.config/nvim/lua/nvim-comple.lua
luafile $HOME/.config/nvim/lua/treesitter.lua
luafile $HOME/.config/nvim/lua/galaxyline.lua
luafile $HOME/.config/nvim/lua/gitsigns.lua
" luafile $HOME/.config/nvim/lua/bufferline.lua
luafile $HOME/.config/nvim/lua/lspconfig.lua
luafile $HOME/.config/nvim/lua/tabline.lua
