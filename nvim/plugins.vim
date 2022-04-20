let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin("~/.vim/bundle")

Plug 'benmills/vimux'                                           " Vim plugin to interact with tmux
Plug 'tyewang/vimux-jest-test'                                  " Vimux for jest
Plug 'danro/rename.vim'                                         " Rename the current file in the vim buffer + retain relative path.
Plug 'docunext/closetag.vim'                                    " Functions and mappings to close open HTML/XML tags
Plug 'duwanis/tomdoc.vim'                                       " A simple syntax add-on for vim that highlights your TomDoc comments.
Plug 'godlygeek/tabular'                                        " Vim script for text filtering and alignment
Plug 'majutsushi/tagbar'                                        " Vim plugin that displays tags in a window, ordered by scope
Plug 'mileszs/ack.vim'
Plug 'terryma/vim-expand-region'                                " Vim plugin that allows you to visually select increasingly larger regions of text using the same key combination.
Plug 'tomtom/tcomment_vim'                                      " An extensible & universal comment plugin that also handles embedded filetypes
Plug 'tpope/vim-endwise'                                        " wisely add 'end' in ruby, endfunction/endif/more in vim script, etc
Plug 'tpope/vim-fugitive'                                       " a Git wrapper so awesome
Plug 'tpope/vim-ragtag'                                         " Ghetto HTML/XML mappings (formerly allml.vim)
Plug 'tpope/vim-repeat'							                            " repeat.vim: enable repeating supported plugin maps with '.'
Plug 'vim-ruby/vim-ruby' 						                            " Vim/Ruby Configuration Files
Plug 'tmux-plugins/vim-tmux-focus-events'                       " Makes the autoread option work properly for terminal vim
Plug 'kshenoy/vim-signature'                                    " Plugin to toggle, display and navigate marks
Plug 'junegunn/fzf.vim'                                         " 🌸 A command-line fuzzy finder written in Go
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'janko-m/vim-test'                                         " Run your tests at the speed of thought
Plug 'tpope/vim-dispatch'                                       " dispatch.vim: asynchronous build and test dispatcher
Plug 'terryma/vim-multiple-cursors'                             " True Sublime Text style multiple selections for Vim
Plug 'Shougo/denite.nvim'                                       " Denite features
Plug 'supercollider/scvim', { 'branch': 'main' }                                      " Supercolldier
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'rhysd/git-messenger.vim'                                  " Git
Plug 'marko-cerovac/material.nvim', { 'branch': 'main' }
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'lewis6991/gitsigns.nvim' , {'branch': 'main'}
Plug 'kyazdani42/nvim-web-devicons' " Recommended (for coloured icons)
Plug 'kyazdani42/nvim-tree.lua'
Plug 'folke/trouble.nvim'
Plug 'folke/lsp-colors.nvim'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'neovim/nvim-lspconfig'
" Plug 'simrat39/rust-tools.nvim'
Plug 'matze/rust-tools.nvim', { 'branch': 'fix-upstreamed-inlayhints' }
Plug 'nvim-lua/lsp_extensions.nvim'
Plug 'jose-elias-alvarez/nvim-lsp-ts-utils'
" Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'nvim-lua/plenary.nvim'
" Plug 'nvim-lua/completion-nvim'
Plug 'mhinz/vim-startify'
Plug 'mhartington/formatter.nvim'
Plug 'nvim-lua/popup.nvim'
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
Plug 'mfussenegger/nvim-dap'
Plug 'folke/which-key.nvim'
Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}
Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'}
Plug 'ms-jpq/coq.thirdparty', {'branch': '3p'}
Plug 'windwp/nvim-autopairs'
Plug 'David-Kunz/jester'
Plug 'machakann/vim-sandwich'
Plug 'metakirby5/codi.vim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'sidebar-nvim/sidebar.nvim', { 'branch': 'main'}
Plug 'wincent/vim-clipper', { 'branch': 'main'}
Plug 'github/copilot.vim', { 'branch': 'release' }

call plug#end()

