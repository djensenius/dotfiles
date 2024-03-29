#!/usr/bin/env bash
# GitHub codespaces setup.

function link_files() {
    mkdir -p ~/.config
    ln -s $(pwd)/tmux.conf ~/.tmux.conf
    rm ~/.gitconfig
    ln -s $(pwd)/gitconfig ~/.gitconfig
    ln -s $(pwd)/gitignore_local ~/.gitignore_local
    ln -s $(pwd)/fish ~/.config/
    ln -s $(pwd)/starship.toml ~/.config/
    ln -s $(pwd)/nvim ~/.config/
    ln -s $(pwd)/bat ~/.config/
    ln -s $(pwd)/vale.ini ~/.vale.ini
    ln -s $(pwd)/prettierrc.json ~/.config/prettierrc.json
    ln -s $(pwd)/gitmux.conf ~/.config/gitmux.conf
    ln -s $(pwd)/tmuxinator ~/.config/tmuxinator
    ln -s $(pwd)/neofetch ~/.config/neofetch
    cd /workspaces/github
    git status
    if [ -d /workspaces/github ]; then
      sudo ln -s /workspaces/github/bin/rubocop /usr/local/bin/rubocop
      sudo ln -s /workspaces/github/bin/srb /usr/local/bin/srb
      sudo ln -s /workspaces/github/bin/bundle /usr/local/bin/bundle
      sudo ln -s /workspaces/github/bin/solargraph /usr/local/bin/solargraph
      sudo ln -s /workspaces/github/bin/safe-ruby /usr/local/bin/safe-ruby
      sudo update-locale LANG=en_US.UTF-8 LC_TYPE=en_US.UTF-8 LC_ALL=en_US.UTF-8
    fi
}

function install_software() {
    sleep 20
    sudo apt -o DPkg::Lock::Timeout=600 install build-essential python3-venv kitty-terminfo socat ncat ruby-dev jq thefuck tmux libfuse2 fuse software-properties-common most -y
    sudo apt remove bat ripgrep -y
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
    # sudo apt-get install -y ca-certificates curl gnupg
    # sudo mkdir -p /etc/apt/keyrings
    # curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    # NODE_MAJOR=20
    # echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    # sudo apt-get update
    # sudo apt-get install -y nodejs
    curl -L https://github.com/dandavison/delta/releases/download/0.17.0/git-delta-musl_0.17.0_amd64.deb > ~/git-delta-musl_0.17.0_amd64.deb
    sudo dpkg -i ~/git-delta-musl_0.17.0_amd64.deb
    cargo install exa
    cargo install zoxide --locked
    cargo install ripgrep
    cargo install fd-find
    cargo install bat --locked
    go install github.com/arl/gitmux@latest
    sudo gem install tmuxinator
    npm install -g @fsouza/prettierd
    curl -L https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.fish > ~/.config/fish/completions/
    ~/.cargo/bin/bat cache --build
}

function setup_software() {
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
    sudo chsh -s /usr/bin/fish vscode
}

echo '🔗 Linking files.' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
link_files
echo '💽 Installing software' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
install_software
echo '👩<200d>🔧 configure software' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
setup_software
echo '✅ Done!' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;

