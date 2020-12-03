set rtp+=/usr/local/opt/fzf
let $FZF_DEFAULT_COMMAND = 'rg --hidden -l ""'
let g:fzf_files_options = '--preview "bat {2..-1} | head -'.&lines.'"'

silent! nnoremap <unique> <silent> <leader>f :FZF<CR>
silent! nnoremap <unique> <silent> <leader>b :Buffers<CR>
" silent! nnoremap <unique> <silent> <leader>fg :Commits<CR>
" Maps, Tags, BCommits are also useful ones.

" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

" [[B]Commits] Customize the options used by 'git log'
let g:fzf_commits_log_options ='--pretty=format:"%C(yellow)%h%Creset %ad %s %C(red)[%an]%Creset" --graph --date=short'

