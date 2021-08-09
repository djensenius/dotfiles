call plug#begin("~/.vim/bundle")

Plug 'Townk/vim-autoclose'                                      " This plugin for Vim enable an auto-close chars feature for you
Plug 'benmills/vimux'                                           " Vim plugin to interact with tmux
Plug 'tyewang/vimux-jest-test'                                  " Vimux for jest
Plug 'danro/rename.vim'                                         " Rename the current file in the vim buffer + retain relative path.
Plug 'docunext/closetag.vim'                                    " Functions and mappings to close open HTML/XML tags
Plug 'duwanis/tomdoc.vim'                                       " A simple syntax add-on for vim that highlights your TomDoc comments.
Plug 'ervandew/supertab'                                        " Perform all your vim insert mode completions with Tab
Plug 'godlygeek/tabular'                                        " Vim script for text filtering and alignment
Plug 'majutsushi/tagbar'                                        " Vim plugin that displays tags in a window, ordered by scope
Plug 'mileszs/ack.vim'
Plug 'terryma/vim-expand-region'                                " Vim plugin that allows you to visually select increasingly larger regions of text using the same key combination.
Plug 'tomtom/tcomment_vim'                                      " An extensible & universal comment plugin that also handles embedded filetypes
Plug 'tpope/vim-endwise'                                        " wisely add 'end' in ruby, endfunction/endif/more in vim script, etc
Plug 'tpope/vim-fugitive'                                       " a Git wrapper so awesome
Plug 'tpope/vim-ragtag'                                         " Ghetto HTML/XML mappings (formerly allml.vim)
Plug 'tpope/vim-repeat'							                            " repeat.vim: enable repeating supported plugin maps with '.'
Plug 'tpope/vim-surround' 					                            " surround.vim: quoting/parenthesizing made simple
Plug 'vim-ruby/vim-ruby' 						                            " Vim/Ruby Configuration Files
" Plug 'itchyny/lightline.vim'
Plug 'glepnir/galaxyline.nvim' , {'branch': 'main'}
Plug 'tmux-plugins/vim-tmux-focus-events'                       " Makes the autoread option work properly for terminal vim
Plug 'kshenoy/vim-signature'                                    " Plugin to toggle, display and navigate marks
Plug 'junegunn/fzf.vim'                                         " 🌸 A command-line fuzzy finder written in Go
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'janko-m/vim-test'                                         " Run your tests at the speed of thought
Plug 'tpope/vim-dispatch'                                       " dispatch.vim: asynchronous build and test dispatcher
" Plug 'yuezk/vim-js'
" Plug 'maxmellon/vim-jsx-pretty'
Plug 'terryma/vim-multiple-cursors'                             " True Sublime Text style multiple selections for Vim
" Plug 'HerringtonDarkholme/yats.vim'                             " TypeScript synax file
Plug 'Shougo/denite.nvim'                                       " Denite features
Plug 'kyazdani42/nvim-web-devicons'

" Plug 'peitalin/vim-jsx-typescript'
" Plug 'leafgarland/typescript-vim'
Plug 'puremourning/vimspector'
Plug 'supercollider/scvim', { 'branch': 'main' }                                      " Supercolldier
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
" Plug 'rust-lang/rust.vim'                                       " Rust!
Plug 'rhysd/git-messenger.vim'                                  " Git
Plug 'rakr/vim-one'
Plug 'joshdick/onedark.vim'
Plug 'sonph/onehalf', { 'rtp': 'vim/' }
Plug 'marko-cerovac/material.nvim', { 'branch': 'main' }
" Plug 'glepnir/indent-guides.nvim', { 'branch': 'main' }                               " Async indentation guides
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'lewis6991/gitsigns.nvim' , {'branch': 'main'}
Plug 'kyazdani42/nvim-web-devicons' " Recommended (for coloured icons)
Plug 'kyazdani42/nvim-tree.lua'
Plug 'folke/trouble.nvim'
Plug 'folke/lsp-colors.nvim'
" This was the tab bar I was using before
" Plug 'akinsho/nvim-bufferline.lua'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'neovim/nvim-lspconfig'
Plug 'jose-elias-alvarez/nvim-lsp-ts-utils'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'nvim-lua/plenary.nvim'
" Plug 'nvim-lua/completion-nvim'
Plug 'hrsh7th/nvim-compe'
Plug 'mhinz/vim-startify'
Plug 'mhartington/formatter.nvim'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'kblin/vim-fountain'
Plug 'onsails/lspkind-nvim'
Plug 'kosayoda/nvim-lightbulb'
Plug 'RishabhRD/popfix' " Required by lsputils
Plug 'RishabhRD/nvim-lsputils' " Enhance built in LSP functions
Plug 'ray-x/guihua.lua', {'do': 'cd lua/fzy && make' }
Plug 'ray-x/navigator.lua'
Plug 'alvarosevilla95/luatab.nvim'
Plug 'vim-test/vim-test'
Plug 'rcarriga/vim-ultest', { 'do': ':UpdateRemotePlugins' }
Plug 'liuchengxu/vista.vim'

call plug#end()

" set completeopt=menuone,noinsert,noselect
" let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']

