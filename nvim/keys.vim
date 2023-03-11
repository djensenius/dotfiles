" Move around splits with <c-hjkl>
nmap <C-k> <C-w><Up>
nmap <C-j> <C-w><Down>
nmap <C-l> <C-w><Right>
nmap <C-h> <C-w><Left>

imap <C-k> <Up>
imap <C-j> <Down>
imap <C-l> <Right>
imap <C-h> <Left>

" Buffer and tab operations with <s-hjkl>
nnoremap <s-h> :bprevious<cr>
nnoremap <s-l> :bnext<cr>
nnoremap <s-j> :tabnext<cr>
nnoremap <s-k> :tabprev<cr>
nnoremap <s-t> :tabnew<cr>

" Window navi
nnoremap <c-w>j 3<c-w>+
nnoremap <c-w>k 3<c-w>-
nnoremap <c-w>h 3<c-w><
nnoremap <c-w>l 3<c-w>>

" Clear the search buffer when hitting return
function! MapCR()
  nnoremap <c-n> :nohlsearch<cr>
endfunction
call MapCR()

" Paste with <F3>
nnoremap <F3> :set invpaste paste?<CR>
set pastetoggle=<F3>

" Remove trailing whitespaces
" nnoremap <silent> <F4> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar>:nohl<CR>

" Automatically jump to end of text you pasted
vnoremap <silent> y y`]
vnoremap <silent> p p`]
nnoremap <silent> p p`]
nnoremap x "_x

" Playback of recorded keys. http://goo.gl/ZlXa8X
" start by qq, end by q, replay by Q
noremap Q @q

" Auto center on matched string.
noremap n nzz
noremap N Nzz

let mapleader=","
" nmap <leader>bp orequire'pry-byebug';binding.pry<ESC>
" Nab lines from ~/.pry_history (respects 'count')
" nmap <Leader>bph :<c-u>let pc = (v:count1 ? v:count1 : 1)<cr>:read !tail -<c-r>=pc<cr> ~/.pry_history<cr>:.-<c-r>=pc-1<cr>:norm <c-r>=pc<cr>==<cr>
" nmap <leader>co i# Copyright (c) 2015 Di Wen <ifyouseewendy@gmail.com><ESC>
nmap <leader>no :set nonu<cr>
nmap <leader>nu :set nu<cr>
nmap <leader>rn :set rnu<cr>
nmap <leader>nrn :set nornu<cr>
nmap <leader>nh :nohls<cr>
nmap <leader>so :source ~/.config/nvim/init.vim<cr>
nmap <leader>tt :TroubleToggle<cr>
" nmap <leader>se :vsp ~/.vimrc<cr>
" nmap <leader>sf :w<cr>:Format<cr>
" nmap <leader>w :wq<cr>
" nmap <leader>s :w<cr>
" nmap <leader>e :e!<cr>
" nmap <leader>q :q!<cr>
cmap w!! %!sudo tee > /dev/null %
command! InsertTime :normal a<c-r>=strftime('%F %H:%M:%S')<cr>
command! InsertDate :normal a<c-r>=strftime('%F')<cr>

" System clipboard copy/paste
if has('macunix')
  set clipboard=unnamedplus
endif
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P


" Quick window split
map <leader>sp :split<cr>
map <leader>sv :vsplit<cr>
map <leader>\| :vsplit<cr>
map <leader>- :split<cr>

" Select entire line without newline
" nnoremap <leader>v<CR> 0vg_

" SuperCollider
" map <leader>ss :SClangStart

let g:oscyank_term = 'default'
autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '' | execute 'OSCYankRegister "' | endif
autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '+' | execute 'OSCYankRegister +' | endif
