let g:ackprg_working_path_mode="r" "always start searching from your project root instead of the cwd
if executable('rg')
  let g:ackprg="rg --vimgrep --no-heading"

  nnoremap <leader>a :Ag

  " Word under cursor
  nnoremap <leader>A :Ag! "\b<C-R><C-W>\b"<CR>:cw<CR>

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  " let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " ag is fast enough that CtrlP doesn't need to cache
  " let g:ctrlp_use_caching = 0
  " Migrating from ag.vim
  cnoreabbrev ag Ack
  cnoreabbrev aG Ack
  cnoreabbrev Ag Ack
  cnoreabbrev AG Ack

  " ripgrep
  let g:ctrlp_user_command = 'rg --files %s'
  let g:ctrlp_use_caching = 0
  let g:ctrlp_working_path_mode = 'ra'
  let g:ctrlp_switch_buffer = 'et'
endif

" Close quickfix window
map <leader>cc :ccl<cr>
map <leader>co :copen<cr>
au FileType qf call AdjustWindowHeight(3, 10)
function! AdjustWindowHeight(minheight, maxheight)
  exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
endfunction

