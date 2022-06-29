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

function install_homebrew() {
    if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]
    then
      echo "Brew alread installed" >> ~/install.log
    else
      NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
      NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ${HOME}/.profile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "Homebrew installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    sleep 5
    # sudo apt-get update
    sudo apt-get install build-essential python3-venv kitty-terminfo socat ncat npm ruby-dev -y
    echo "Apt get installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    brew bundle install --global
    echo "Bundle installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    sudo npm install -g typescript-language-server typescript vscode-langservers-extracted eslint_d
    echo "NPM installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    # From https://www.reddit.com/r/neovim/comments/pu43bb/neovim_lsp_with_solargraph_issues/
    sudo gem install solargraph
    echo "Solargraph installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    solargraph download-core
    echo "Solargraph core downloaded" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
}

function setup_software() {
    echo "/home/linuxbrew/.linuxbrew/bin/fish" | sudo tee -a /etc/shells
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
      sudo chsh -s /home/linuxbrew/.linuxbrew/bin/fish vscode
    fi

    if [-d "/home/codespace "]
    then
      sudo chsh -s /home/linuxbrew/.linuxbrew/bin/fish codespace
    fi
}

echo '🔗 Linking files.' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
link_files
echo '💽 Installing software' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
install_homebrew
echo '👩<200d>🔧 configure software' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
setup_software
echo '✅ Done!' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;

