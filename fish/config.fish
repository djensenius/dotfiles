starship init fish | source
thefuck --alias | source
abbr --add 'monolith' 'gh cs create -R github/github -m xLargePremiumLinux  --devcontainer-path .devcontainer/devcontainer.json --status'
abbr --add 'youtub-dl' 'yt-dlp'
if test -e /home/linuxbrew
  eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

if test -e ~/.fish_env
  envsource ~/.fish_env
end

zoxide init fish | source

if test -e /workspaces/.codespaces/shared/.env
  # posix-source /workspaces/.condespaces/shared/.env
else
  status --is-interactive; and rbenv init - fish | source
end
