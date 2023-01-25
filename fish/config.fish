# set -Ux PYENV_ROOT $HOME/.pyenv
# set -U fish_user_paths $PYENV_ROOT/bin $fish_user_paths
# source $HOME/.cargo/env
# set -g fish_user_paths "/usr/local/sbin" $fish_user_paths
# set -g fish_user_paths "$HOME/.cargo/bin" $fish_user_paths
# fish_add_path /home/linuxbrew/.linuxbrew/bin
# fish_add_path /home/linuxbrew/.linuxbrew/sbin
# fish_add_path /workspaces/github/bin
starship init fish | source
# status --is-interactive; and source (rbenv init -|psub)
# set -g fish_user_paths "/usr/local/opt/openssl@1.1/bin" $fish_user_paths
# set -g fish_user_paths "/usr/local/opt/ncurses/bin" $fish_user_paths
thefuck --alias | source
eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
if test -e /workspaces/.codespaces/shared/.env
  # posix-source /workspaces/.condespaces/shared/.env
else
  status --is-interactive; and rbenv init - fish | source
end
