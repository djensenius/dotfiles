call plug#begin("~/.vim/bundle")

Plug 'Townk/vim-autoclose'                                      " This plugin for Vim enable an auto-close chars feature for you
Plug 'Yggdroot/indentLine'                                      " A vim plugin to display the indention levels with thin vertical lines
Plug 'airblade/vim-gitgutter'                                   " A Vim plugin which shows a git diff in the gutter (sign column) and stages/undoes hunks
Plug 'benmills/vimux'                                           " Vim plugin to interact with tmux
Plug 'tyewang/vimux-jest-test'                                  " Vimux for jest
Plug 'danro/rename.vim'                                         " Rename the current file in the vim buffer + retain relative path.
Plug 'docunext/closetag.vim'                                    " Functions and mappings to close open HTML/XML tags
Plug 'duwanis/tomdoc.vim'                                       " A simple syntax add-on for vim that highlights your TomDoc comments.
Plug 'ervandew/supertab'                                        " Perform all your vim insert mode completions with Tab
Plug 'godlygeek/tabular'                                        " Vim script for text filtering and alignment
Plug 'majutsushi/tagbar'                                        " Vim plugin that displays tags in a window, ordered by scope
Plug 'mileszs/ack.vim'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }          " A tree explorer plugin for vim
Plug 'terryma/vim-expand-region'                                " Vim plugin that allows you to visually select increasingly larger regions of text using the same key combination.
Plug 'tomtom/tcomment_vim'                                      " An extensible & universal comment plugin that also handles embedded filetypes
Plug 'tpope/vim-endwise'                                        " wisely add 'end' in ruby, endfunction/endif/more in vim script, etc
Plug 'tpope/vim-fugitive'                                       " a Git wrapper so awesome
Plug 'tpope/vim-ragtag'                                         " Ghetto HTML/XML mappings (formerly allml.vim)
Plug 'tpope/vim-repeat'							                            " repeat.vim: enable repeating supported plugin maps with '.'
Plug 'tpope/vim-surround' 					                            " surround.vim: quoting/parenthesizing made simple
Plug 'vim-ruby/vim-ruby' 						                            " Vim/Ruby Configuration Files
" Plug 'vim-airline/vim-airline'                                  " Lean & mean status/tabline for vim that's light as air
" Plug 'vim-airline/vim-airline-themes'
Plug 'itchyny/lightline.vim'
Plug 'tmux-plugins/vim-tmux-focus-events'                       " Makes the autoread option work properly for terminal vim
Plug 'kshenoy/vim-signature'                                    " Plugin to toggle, display and navigate marks
Plug 'junegunn/fzf.vim'                                         " 🌸 A command-line fuzzy finder written in Go
Plug 'janko-m/vim-test'                                         " Run your tests at the speed of thought
Plug 'tpope/vim-dispatch'                                       " dispatch.vim: asynchronous build and test dispatcher
Plug 'yuezk/vim-js'
Plug 'maxmellon/vim-jsx-pretty'
" Plug 'dracula/vim'                                              " A dark theme for Vim
Plug 'terryma/vim-multiple-cursors'                             " True Sublime Text style multiple selections for Vim
Plug 'HerringtonDarkholme/yats.vim'                             " TypeScript synax file
Plug 'Shougo/denite.nvim'                                       " Denite features
Plug 'ryanoasis/vim-devicons'                                   " Icons for files
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'                  " NerdTree icons
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'peitalin/vim-jsx-typescript'
Plug 'leafgarland/typescript-vim'
Plug 'puremourning/vimspector'
Plug 'supercollider/scvim'                                      " Supercolldier
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'rust-lang/rust.vim'                                       " Rust!
Plug 'rhysd/git-messenger.vim'                                  " Git
Plug 'rakr/vim-one'
Plug 'joshdick/onedark.vim'

call plug#end()

