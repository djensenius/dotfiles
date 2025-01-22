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
end
zoxide init fish | source

if test -d /workspaces
  fish_add_path $(npm config get prefix)
  fish_add_path $(npm config get prefix)/bin
  fish_add_path --path ~/.fzf/bin
end

if test -e /etc/dfj-container
  fish_add_path /opt/nvim-linux64/bin
end

if test -e /workspaces/.codespaces/shared/.env
  # posix-source /workspaces/.condespaces/shared/.env
else
  status --is-interactive; and rbenv init - fish | source
end

fzf --fish | source

alias gt="tmuxinator start github"
alias pt="tmuxinator start personal"
alias st="tmuxinator start server"
alias fzg="rgf"

if status is-interactive
  atuin init fish | source
  if test -d /workspaces
    if not test -e ~/.atuin_logged_in
      ~/.cargo/bin/atuin login -u $ATUIN_USERNAME -p $ATUIN_PASSWORD -k $ATUIN_KEY
      touch ~/.atuin_logged_in
    end
  end
end

if test -d /home/linuxbrew/.linuxbrew/opt/asdf
  source /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.fish
end

if test -d ~/.asdf/plugins/golang
  source ~/.asdf/plugins/golang/set-env.fish
end

set -Ux FZF_DEFAULT_OPTS "\
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi"
