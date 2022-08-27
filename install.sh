#!/usr/bin/env bash
# GitHub codespaces setup.

function link_files() {
        mkdir -p ~/.config
        ln -s $(pwd)/Brewfile.headless ~/.Brewfile
        ln -s $(pwd)/tmux.conf ~/.tmux.conf
        ln -s $(pwd)/gitconfig ~/.gitconfig
        ln -s $(pwd)/fish ~/.config/
        ln -s $(pwd)/starship.toml ~/.config/
        ln -s $(pwd)/nvim ~/.config/
        ln -s $(pwd)/vale.ini ~/.vale.ini
        sudo ln -s /workspaces/github/bin/rubocop /usr/local/bin/rubocop
        sudo ln -s /workspaces/github/bin/srb /usr/local/bin/srb
        sudo ln -s /workspaces/github/bin/solargraph /usr/local/bin/solargraph
}

function install_software() {
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
    curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -
    sudo apt-get install -y nodejs
    curl https://github.com/dandavison/delta/releases/download/0.13.0/git-delta_0.13.0_amd64.deb > ~/git-delta_0.13.0_amd64.deb
    sudo dpkg -i ~/git-delta_0.13.0_amd64.deb
    sudo npm install -g typescript-language-server typescript vscode-langservers-extracted eslint_d
    sudo apt -o DPkg::Lock::Timeout=600 install build-essential python3-venv kitty-terminfo socat ncat ruby-dev bat exa jq ripgrep thefuck tmux libfuse2 fuse software-properties-common -y
}

function setup_software() {
    sudo chsh -s /usr/bin/fish vscode
    /usr/bin/pip3 install neovim
    echo "PIP install neovim complete" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    mkdir -p ~/.config/github-copilot
    echo '{"djensenius":{"version":"2021-10-14"}}' > ~/.config/github-copilot/terms.json
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    echo "TMUX plugins installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    # rm ~/.gitconfig
    # ln -s $(pwd)/gitconfig ~/.gitconfig
    nvim --headless +PlugInstall +qa &> /dev/null
    sleep 5
    echo "NVIM plugins installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    # cd ~/.vim/bundle/coq_nvim/
    # python3 -m coq deps
    # echo "Python coq deps finished" >> ~/install.log
    # echo `date +"%Y-%m-%d %T"` >> ~/install.log;
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

