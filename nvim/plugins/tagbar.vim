nmap <F2> :TagbarToggle<CR>
map <F5> :!/usr/local/bin/ctags --recurse=yes --languages=-javascript --exclude=.git --exclude=log --fields=+iaS --extra=+q .<CR>
map <F6> :tprevious<CR>
map <F7> :tnext<CR>
set tags=./tags;
