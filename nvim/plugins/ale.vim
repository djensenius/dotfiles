" Run linters only a file is saved
let g:ale_lint_on_text_changed = 'normal'
" Want linters to run on opening a file
let g:ale_lint_on_enter = 1

" Enable particular linters
let g:ale_linters = {
\   'javascript': ['stylelint', 'eslint', 'flow'],
\   'scss': ['stylelint'],
\   'json': ['jsonlint'],
\   'yaml': ['yamllint'],
\   'ruby': ['ruby', 'rubocop'],
\   'eruby': [],
\   'haskell': ['hlint', 'stack-ghc-mod'],
\   'typescript': ['tsserver', 'tslint'],
\}

let g:ale_yaml_yamllint_options = "-c ~/.yamllint"

" Config :ALEFix to use prettier
let g:ale_fixers = {
\  'javascript': ['prettier'],
\  'json': ['prettier'],
\  'ruby': ['rubocop'],
\  'css': ['stylelint'],
\  'typescript': ['prettier'],
\}

let g:ale_javascript_prettier_options = "--trailing-comma all"
let g:ale_scss_stylelint_options = "--fix"

" Run fixer on save
let g:ale_fix_on_save = 0

" Message format
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'

nmap <silent> <leader>lj <Plug>(ale_next_wrap)
nmap <silent> <leader>lk <Plug>(ale_previous_wrap)

nmap <silent> <leader>= <Plug>(ale_fix)

