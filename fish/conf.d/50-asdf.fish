# asdf completions and Golang plugin env
if test -d /home/linuxbrew/.linuxbrew/opt/asdf
    source /home/linuxbrew/.linuxbrew/opt/asdf/share/fish/vendor_completions.d/asdf.fish
end

if test -d ~/.asdf/plugins/golang
    source ~/.asdf/plugins/golang/set-env.fish
end
