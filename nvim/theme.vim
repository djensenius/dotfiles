let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set termguicolors
set t_8b=[48;2;%lu;%lu;%lum
set t_8f=[38;2;%lu;%lu;%lum

colorscheme onedark
set background=dark
let g:one_allow_italics = 1

function! SourceFileExists(file)
  if filereadable(expand(a:file))
    return "true"
  endif
  return "false"
endfunction

function! UpdateTheme()
  if SourceFileExists("~/.darkmode") == "true"
    colorscheme onedark
    set background=dark
    execute 'runtime autoload/lightline/colorscheme/one.vim'
    let g:lightline.colorscheme = 'one'
    call lightline#init()
    call lightline#colorscheme()
    call lightline#update()
    highlight Normal guibg=black
  else
    colorscheme one
    set background=light
    execute 'runtime autoload/lightline/colorscheme/one.vim'
    let g:lightline.colorscheme = 'one'
    call lightline#init()
    call lightline#colorscheme()
    call lightline#update()
  endif
endfunction

autocmd CursorHold * silent call UpdateTheme()
let g:lightline = {
      \ 'colorscheme': 'one',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'filetype': 'MyFiletype',
      \   'fileformat': 'MyFileformat',
      \   'gitbranch': 'FugitiveHead',
      \ },
      \ 'tabline': {
      \   'left': [ ['buffers'] ],
      \   'right': [ ['close'] ]
      \ },
      \ 'component_expand': {
      \   'buffers': 'lightline#bufferline#buffers'
      \ },
      \ 'component_type': {
      \   'buffers': 'tabsel'
      \ }
  \ }

let g:lightline#bufferline#enable_devicons = 1
let g:lightline.component_raw = {'buffers': 1}
let g:lightline#bufferline#clickable = 1
let g:lightline#bufferline#unicode_symbols = 1

function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype . ' ' . WebDevIconsGetFileTypeSymbol() : 'no ft') : ''
endfunction

function! MyFileformat()
  return winwidth(0) > 70 ? (&fileformat . ' ' . WebDevIconsGetFileFormatSymbol()) : ''
endfunction

