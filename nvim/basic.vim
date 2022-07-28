" Basic configuration
syntax on
set nu
set noshowmode
set ruler                                   " Show the line and column number of the cursor position.
set showcmd                                 " Show the size of block one selected in visual mode.
set nobackup
set noswapfile                              " Disable swap to prevent annoying messages.
set fdm=marker
set bs=2
set backspace=indent,eol,start              " Allow backspacing over everything in insert mode
set diffopt+=iwhite                         " Ignore whitespaces with vimdiff
set statusline+=%f                          " Display relative path
set complete-=i                             " Don't scan included files. The .tags file is more performant
set nrformats=                              " Treat all numerals as decimal. Use <c-a> on 007 and return 008, not octal 010
set laststatus=2                            " Always show window statuses, even if there's only one.
set autoread                                " Reload unchanged files automatically.
set fileformats+=mac                        " Support all kind of EOLs by default.
set history=1000                            " Increase history size to 1000 items.
" set cursorline                              " Highlight line under cursor. It helps with navigation.
set scrolloff=8                             " Keep 8 lines above or below the cursor when scrolling.
set sidescroll=1                            " Keep 15 columns next to the cursor when scrolling horizontally.
set sidescrolloff=15
set wrap linebreak                          " Wrap lines by default
set showbreak=" "
set noerrorbells                            " Disable any annoying beeps on errors.
set visualbell
set nomodeline                              " Don't parse modelines (google 'vim modeline vulnerability')
set iskeyword+=-                            " Use dash as word separator.
set wildchar=<Tab> wildmenu wildmode=full   " Tab triggers buffer-name auto-completion
set wildmenu                                " Autocomplete commands using nice menu in place of window status.

" Tab/indent configuration
set tabstop=2
set shiftwidth=2
set expandtab
set softtabstop=2
set autoindent                              " Autoindent when starting new line, or using o or O
set cindent
set smarttab                                " Use 'shiftwidth' when using <Tab> in front of a line. By default it's used only for shift commands (<, >).

" Search configuration
set smartcase                               " Don't ignore case when search has capital letter (although also don't ignore case by default).
set ignorecase                              " Ignore case when searching.
set hlsearch                                " Enable search highlighting.
set incsearch                               " Enable highlighted case-insensitive incremential search.

" Undo file settings
set undodir=~/.vim/.undo
set undofile
set undolevels=1000
set undoreload=10000
set updatetime=100

" Encoding configuration
" set encoding=utf-8
" set fileencoding=utf-8
" set fileencodings=utf-8,ucs-bom,chinese
set formatoptions+=mM
set conceallevel=2 concealcursor=i

" Highlight trailing whitespace
" highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()
autocmd InsertEnter * set cul
autocmd InsertLeave * set nocul

" Filetype detection
autocmd BufNewFile,BufRead Thorfile set filetype=ruby
autocmd BufNewFile,BufRead *.thor set filetype=ruby
autocmd BufNewFile,BufRead Gemfile set filetype=ruby
autocmd BufNewFile,BufRead Capfile set filetype=ruby
autocmd BufNewFile,BufRead pryrc set filetype=ruby
autocmd BufNewFile,BufRead *.god set filetype=ruby
autocmd BufNewFile,BufRead *.less set filetype=css
autocmd BufNewFile,BufRead *.mkd, *md set ai formatoptions=tcroqn2 comments=n:>
autocmd BufNewFile,BufRead *.babel set filetype=javascript
autocmd BufNewFile,BufRead **/TLX/**.xml set filetype=javascript
autocmd Filetype gitcommit setlocal textwidth=72
autocmd FileType c setlocal tabstop=8 shiftwidth=4 softtabstop=4
autocmd FileType elm set ai ts=4 sw=4 sts=4 et
autocmd Filetype javascript setlocal ts=2 sw=2 sts=0 expandtab
autocmd BufNewFile,BufRead,BufEnter **/macross/** setlocal ts=4 sw=4 sts=4 expandtab
autocmd BufNewFile,BufRead,BufEnter **/macross-brain/** setlocal ts=4 sw=4 sts=4 expandtab
autocmd BufNewFile,BufRead,BufEnter **/TLX/**.xml setlocal ts=4 sw=4 sts=0 expandtab filetype=javascript

" Linting
autocmd BufWritePost,BufRead,InsertLeave,TextChanged *.md lua require('lint').try_lint()
autocmd BufWritePost,BufRead,InsertLeave,TextChanged *.txt lua require('lint').try_lint()
autocmd BufWritePost,BufRead,InsertLeave,TextChanged *.rb lua require('lint').try_lint()

" nvim
if has('nvim')
  " let g:python_host_prog = '/Users/david/.pyenv/versions/neovim2/bin/python'
  " let g:python3_host_prog = '/Users/david/.pyenv/versions/neovim3/bin/python'
  let g:python3_host_prog = '/usr/bin/python3'

  " nmap <BS> <C-W>h
  " Fix c-h issue by https://github.com/neovim/neovim/issues/2048#issuecomment-162072750
  "
  " Udpate: Fix by https://github.com/neovim/neovim/issues/2048 without
  " setting c-h as escape [104;5u in iterm

  " set mouse-=a " Disable mouse
  set mouse=a " Enable mouse

  if (has("termguicolors"))
    set termguicolors
  endif
endif

if !has('nvim')
  set ttyfast " Send more characters at a given time
endif

" highlight Normal guibg=black guifg=white
" highlight Normal guibg=black
" highlight SignColumn guibg=black

" Load all plugins now.
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL

