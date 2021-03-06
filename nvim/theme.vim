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

" Disabling until I need mode switching again
" autocmd CursorHold * silent call UpdateTheme()
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
      \ }
  \ }

let g:lightline.enable = {
  \ 'statusline': 1,
  \ 'tabline': 0
\ }

lua require'bufferline'.setup{options = {separator_style = "thin"}}

function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype . ' ' . WebDevIconsGetFileTypeSymbol() : 'no ft') : ''
endfunction

function! MyFileformat()
  return winwidth(0) > 70 ? (&fileformat . ' ' . WebDevIconsGetFileFormatSymbol()) : ''
endfunction

