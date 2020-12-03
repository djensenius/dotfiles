let test#strategy = "vimux"

nmap <silent> <leader>tl :TestNearest<CR>
nmap <silent> <leader>ts :TestSuite<CR>
nmap <silent> <leader>tf :TestFile<CR>
nmap <silent> <leader>tg :TestVisit<CR>

let test#javascript#jest#options = {
\ 'suite': '--bail',
\}
