let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin("~/.vim/bundle")

Plug 'benmills/vimux'                                           " Vim plugin to interact with tmux
Plug 'danro/rename.vim'                                         " Rename the current file in the vim buffer + retain relative path.
Plug 'tpope/vim-endwise'                                        " wisely add 'end' in ruby, endfunction/endif/more in vim script, etc
Plug 'tpope/vim-repeat'							                            " repeat.vim: enable repeating supported plugin maps with '.'
Plug 'junegunn/fzf.vim'                                         " 🌸 A command-line fuzzy finder written in Go
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'supercollider/scvim', { 'branch': 'main' }                                      " Supercolldier
Plug 'marko-cerovac/material.nvim', { 'branch': 'main' }
Plug 'EdenEast/nightfox.nvim',
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'lewis6991/gitsigns.nvim' , {'branch': 'main'}
Plug 'kyazdani42/nvim-web-devicons' " Recommended (for coloured icons)
Plug 'kyazdani42/nvim-tree.lua'
Plug 'folke/trouble.nvim'
Plug 'folke/lsp-colors.nvim'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'williamboman/nvim-lsp-installer'
Plug 'neovim/nvim-lspconfig'
Plug 'simrat39/rust-tools.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'mhinz/vim-startify'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'antoinemadec/FixCursorHold.nvim'
Plug 'onsails/lspkind-nvim'
Plug 'kosayoda/nvim-lightbulb'
Plug 'RishabhRD/popfix' " Required by lsputils
Plug 'RishabhRD/nvim-lsputils' " Enhance built in LSP functions
Plug 'ray-x/guihua.lua', {'do': 'cd lua/fzy && make' }
Plug 'ray-x/navigator.lua'
Plug 'alvarosevilla95/luatab.nvim'
Plug 'folke/which-key.nvim'
" Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}
" Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'}
" Plug 'ms-jpq/coq.thirdparty', {'branch': '3p'}
Plug 'nvim-lualine/lualine.nvim'
Plug 'wincent/vim-clipper', { 'branch': 'main'}
Plug 'github/copilot.vim', { 'branch': 'release' }
" Plug 'jose-elias-alvarez/typescript.nvim', { 'branch': 'main' }
Plug 'machakann/vim-sandwich'
Plug 'windwp/nvim-autopairs'
Plug 'pwntester/octo.nvim'
Plug 'mfussenegger/nvim-lint'

call plug#end()

