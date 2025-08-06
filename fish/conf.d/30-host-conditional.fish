# Host-specific toggles for Go proxy (mirrors your config.fish logic, no universals)
if test -d /Users/david
    set -e GOPROXY
else if test -d /Users/djensenius
    set -gx GOPROXY 'https://goproxy.githubapp.com/mod,https://proxy.golang.org/,direct'
end
