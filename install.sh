#!/usr/bin/env bash
# GitHub codespaces setup.

function link_files() {
    mkdir -p ~/.config
    ln -s $(pwd)/Brewfile.headless ~/.Brewfile
    ln -s $(pwd)/tmux.conf ~/.tmux.conf
    rm ~/.gitconfig
    ln -s $(pwd)/gitconfig ~/.gitconfig
    ln -s $(pwd)/gitignore_local ~/.gitignore_local
    ln -s $(pwd)/fish ~/.config/
    ln -s $(pwd)/starship.toml ~/.config/
    ln -s $(pwd)/nvim ~/.config/
    ln -s $(pwd)/bat ~/.config/
    ln -s $(pwd)/vale.ini ~/.vale.ini
    ln -s $(pwd)/prettierrc.json /workspaces/github/.prettierrc.json
    cd /workspaces/github
    git status
    if [ -d ~/workspaces/github ]; then
      sudo ln -s /workspaces/github/bin/rubocop /usr/local/bin/rubocop
      sudo ln -s /workspaces/github/bin/srb /usr/local/bin/srb
      sudo ln -s /workspaces/github/bin/bundle /usr/local/bin/bundle
      sudo ln -s /workspaces/github/bin/solargraph /usr/local/bin/solargraph
      sudo ln -s /workspaces/github/bin/safe-ruby /usr/local/bin/safe-ruby
    fi
}

function install_software() {
    sleep 20
    sudo apt -o DPkg::Lock::Timeout=600 install build-essential python3-venv kitty-terminfo socat ncat ruby-dev jq ripgrep thefuck tmux libfuse2 fuse software-properties-common exa zoxide most -y
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
    curl -sL https://deb.nodesource.com/setup_18.x | sudo bash -
    sudo apt-get install -y nodejs
    curl -L https://github.com/dandavison/delta/releases/download/0.15.1/git-delta-musl_0.15.1_amd64.deb > ~/git-delta-musl_0.15.1_amd64.deb
    sudo dpkg -i ~/git-delta-musl_0.15.1_amd64.deb
    go install github.com/arl/gitmux@latest
}

function setup_generic() {
  sudo apt-get install build-essential
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  rm -rf "/home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/homebrew/homebrew-core"
  brew tap homebrew/core
  brew install gcc fish neovim
}

function setup_software() {
    sudo chsh -s /usr/bin/fish vscode
    /usr/bin/pip3 install neovim
    echo "PIP install neovim complete" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    echo "TMUX plugins installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    nvim --headless "+Lazy! sync" +qa
    echo "NVIM plugins installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
}

echo '🔗 Linking files.' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
link_files
if [ ! -d /home/linuxbrew ]; then
    echo '🍺 Installing brew software' >> ~/install.log;
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    setup_generic
fi
echo '💽 Installing software' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
install_software
echo '👩<200d>🔧 configure software' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
setup_software
echo '✅ Done!' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;

