let test#strategy = "neovim"

nmap <silent> <leader>tl :TestNearest<CR>
nmap <silent> <leader>ts :TestSuite<CR>
nmap <silent> <leader>tf :TestFile<CR>
nmap <silent> <leader>tg :TestVisit<CR>

let test#javascript#mocha#executable = 'NODE_ENV=test; TS_NODE_PROJECT=tsconfig.testing.json; echo $TS_NDOE_PROJECT; node_modules/.bin/mocha'
let test#javascript#mocha#options = '--require ts-node/register'
