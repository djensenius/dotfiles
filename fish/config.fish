starship init fish | source
thefuck --alias | source
abbr --add 'monolith' 'gh cs create -R github/github -m xLargePremiumLinux --devcontainer-path .devcontainer/devcontainer.json --status'
abbr --add 'youtub-dl' 'yt-dlp'
abbr --add 'vim' 'nvim'
if test -e /home/linuxbrew
  eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

if test -e ~/.fish_env
  envsource ~/.fish_env
end

if test -e ~/.cargo/bin
  fish_add_path --path --append ~/.cargo/bin
  zoxide init fish | source
end

if test -d /workspaces
  fish_add_path $(npm config get prefix)
  fish_add_path $(npm config get prefix)/bin
end

if test -e /workspaces/.codespaces/shared/.env
  # posix-source /workspaces/.condespaces/shared/.env
else
  status --is-interactive; and rbenv init - fish | source
end

alias gt="tmuxinator start github"
alias pt="tmuxinator start personal"
alias st="tmuxinator start server"
