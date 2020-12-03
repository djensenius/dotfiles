let g:neocomplcache_enable_at_startup = 1
let g:neocomplcache_enable_camel_case_completion = 1
let g:neocomplcache_enable_smart_case = 1
let g:neocomplcache_enable_underbar_completion = 1
let g:neocomplcache_force_overwrite_completefunc = 1
if !exists('g:neocomplcache_omni_patterns')
  let g:neocomplcache_omni_patterns = {}
endif
let g:neocomplcache_omni_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'

" Enable omni completion.
autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown,mkd setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS

inoremap <expr><C-g>  neocomplcache#undo_completion()
" inoremap <expr><C-l>  neocomplcache#complete_common_string()
inoremap <expr><C-e>  neocomplcache#close_popup()
inoremap <expr><C-y>  neocomplcache#cancel_popup()
inoremap <expr><BS>   neocomplcache#smart_close_popup()."\<C-h>

