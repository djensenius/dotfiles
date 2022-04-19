#!/usr/bin/env bash
# GitHub codespaces setup.

function link_files() {
        mkdir -p ~/.config
        ln -s $(pwd)/Brewfile.headless ~/.Brewfile
        ln -s $(pwd)/tmux.conf ~/.tmux.conf
        ln -s $(pwd)/fish ~/.config/
        ln -s $(pwd)/starship.toml ~/.config/
        ln -s $(pwd)/nvim ~/.config/
}

function install_homebrew() {
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ${HOME}/.profile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    sudo apt-get update
    sudo apt-get install build-essential -y
    brew bundle install --global
}

function setup_software() {
    # sudo chsh -s /usr/bin/fish codespace
    nvim --headless +PlugInstall +qa
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
}

echo '🔗 Linking files.';
link_files
echo '💽 Installing software';
install_homebrew
echo '👩<200d>🔧 configure software';
setup_software
echo '✅ Done!';

