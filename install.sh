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
      echo "Brew alread installed"
    else
      NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
      NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ${HOME}/.profile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    sleep 10
    sudo apt-get update
    sudo apt-get install build-essential python3-venv kitty-terminfo socat ncat npm -y
    brew bundle install --global
    npm install -g typescript-language-server typescript vscode-langservers-extracted eslint_d
}

function setup_software() {
    echo "/home/linuxbrew/.linuxbrew/bin/fish" | sudo tee -a /etc/shells
    /usr/bin/pip3 install neovim
    nvim --headless +PlugInstall +qa
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    rm ~/.gitconfig
    ln -s $(pwd)/gitconfig ~/.gitconfig
    cd ~/.vim/bundle/coq_nvim/
    python3 -m coq deps
    if [ -d "/home/vscode" ]
    then
      sudo chsh -s /home/linuxbrew/.linuxbrew/bin/fish vscode
    fi

    if [-d "/home/codespace "]
    then
      sudo chsh -s /home/linuxbrew/.linuxbrew/bin/fish codespace
    fi
}

echo '🔗 Linking files.';
link_files
echo '💽 Installing software';
install_homebrew
echo '👩<200d>🔧 configure software';
setup_software
echo '✅ Done!';

