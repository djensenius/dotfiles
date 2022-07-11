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
}

function install_software() {
    # sudo apt-get update
    # sudo add-apt-repository universe
    sudo apt-get install build-essential python3-venv kitty-terminfo socat ncat npm ruby-dev bat exa jq ripgrep thefuck tmux libfuse2 fuse fish git-extras software-properties-common -y
    echo "Apt get installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    # sudo add-apt-repository ppa:git-core/ppa -y
    # sudo apt-get update
    # sudo apt-get updrade
    # echo "Apt updated" >> ~/install.log
    # echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    sudo curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage > ~/nvim.appimage
    sudo mv nvim.appimage /usr/bin/nvim
    sudo chmod a+x /usr/bin/nvim
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
    echo "Other software installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    # echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    sudo npm install -g typescript-language-server typescript vscode-langservers-extracted eslint_d
    echo "NPM installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    # From https://www.reddit.com/r/neovim/comments/pu43bb/neovim_lsp_with_solargraph_issues/
    # sudo gem install solargraph
    # echo "Solargraph installed" >> ~/install.log
    # echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    # solargraph download-core
    # echo "Solargraph core downloaded" >> ~/install.log
    # echo `date +"%Y-%m-%d %T"` >> ~/install.log;
}

function setup_software() {
    # echo "/home/linuxbrew/.linuxbrew/bin/fish" | sudo tee -a /etc/shells
    /usr/bin/pip3 install neovim
    echo "PIP install neovim complete" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    nvim --headless +PlugInstall +qa
    echo "NVIM plugins installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    mkdir -p ~/.config/github-copilot
    echo '{"djensenius":{"version":"2021-10-14"}}' > ~/.config/github-copilot/terms.json
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    echo "TMUX plugins installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    rm ~/.gitconfig
    ln -s $(pwd)/gitconfig ~/.gitconfig
    cd ~/.vim/bundle/coq_nvim/
    python3 -m coq deps
    echo "Python coq deps finished" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    if [ -d "/home/vscode" ]
    then
      sudo chsh -s /usr/bin/fish vscode
    fi

    if [ -d "/home/codespace" ]
    then
      sudo chsh -s /usr/bin/fish codespace
    fi
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

