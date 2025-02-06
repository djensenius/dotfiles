#!/usr/bin/env bash
# GitHub codespaces setup.

function link_files() {
    mkdir -p ~/.config
    ln -sf $(pwd)/tmux.conf ~/.tmux.conf
    if [ -e ~/.gitconfig ]; then
      rm ~/.gitconfig
    fi
    ln -s $(pwd)/gitconfig ~/.gitconfig
    ln -sf $(pwd)/gitignore_local ~/.gitignore_local
    if [ -e ~/.config/fish ]; then
      rm -rf ~/.config/fish
    fi
    ln -sf $(pwd)/fish ~/.config/
    ln -sf $(pwd)/starship.toml ~/.config/
    ln -sf $(pwd)/nvim ~/.config/
    ln -sf $(pwd)/bat ~/.config/
    ln -sf $(pwd)/vale.ini ~/.vale.ini
    ln -sf $(pwd)/prettierrc.json ~/.config/prettierrc.json
    ln -sf $(pwd)/gitmux.conf ~/.config/gitmux.conf
    ln -sf $(pwd)/tmuxinator ~/.config/tmuxinator
    ln -sf $(pwd)/neofetch ~/.config/neofetch
    ln -sf $(pwd)/atuin ~/.config/atuin
    ln -sf $(pwd)/yazi ~/.config/yazi
    ln -sf $(pwd)/bottom ~/.config/bottom
    ln -sf $(pwd)/tmux ~/.config/tmux
    if [ -d /workspaces/github ]; then
      sudo ln -sf /workspaces/github/bin/rubocop /usr/local/bin/rubocop
      sudo ln -sf /workspaces/github/bin/srb /usr/local/bin/srb
      sudo ln -sf /workspaces/github/bin/bundle /usr/local/bin/bundle
      sudo ln -sf /workspaces/github/bin/solargraph /usr/local/bin/solargraph
      sudo ln -sf /workspaces/github/bin/safe-ruby /usr/local/bin/safe-ruby
      sudo update-locale LANG=en_US.UTF-8 LC_TYPE=en_US.UTF-8 LC_ALL=en_US.UTF-8
    fi
}

function install_software() {
    if [ -d /workspaces/github ]; then
      sleep 20
      sudo apt -o DPkg::Lock::Timeout=600 install build-essential python3-venv socat ncat ruby-dev jq thefuck tmux libfuse2 fuse software-properties-common most -y
      sudo apt remove bat ripgrep -y
      curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
      curl -L https://github.com/dandavison/delta/releases/download/0.18.2/git-delta-musl_0.18.2_amd64.deb > ~/git-delta-musl_0.18.2_amd64.deb
      sudo dpkg -i ~/git-delta-musl_0.18.2_amd64.deb
      wget --output-document ~/.config/delta-themes.gitconfig https://raw.githubusercontent.com/dandavison/delta/master/themes.gitconfig
      PB_REL="https://github.com/protocolbuffers/protobuf/releases"
      curl -L $PB_REL/download/v25.1/protoc-25.1-linux-x86_64.zip > ~/protoc.zip
      unzip ~/protoc.zip -d $HOME/.local
      export PATH="$PATH:$HOME/.local/bin"
      cargo install eza
      cargo install zoxide --locked
      cargo install ripgrep
      cargo install fd-find
      cargo install bat --locked
      cargo install atuin
      go install github.com/arl/gitmux@latest
      sudo gem install tmuxinator neovim-ruby-host
      npm install -g @fsouza/prettierd yaml-language-server vscode-langservers-extracted eslint_d prettier tree-sitter neovim
      curl -L https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.fish > ~/.config/fish/completions/
      ~/.cargo/bin/bat cache --build
      git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
      ~/.fzf/install --all
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
      curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
      tar xf lazygit.tar.gz lazygit
      sudo install lazygit -D -t /usr/local/bin/
    fi
}

function setup_software() {
    echo "Log in to atuin"
    ~/.cargo/bin/atuin login -u $ATUIN_USERNAME -p $ATUIN_PASSWORD -k $ATUIN_KEY
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    echo "TMUX plugins installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    nvim --headless "+Lazy! sync" +qa
    nvim --headless /tmp/tmp  "+MasonToolsInstallSync" +qa
    echo "NVIM plugins installed" >> ~/install.log
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
    if [ -d /workspaces/github ]; then
      sudo chsh -s /usr/bin/fish vscode
      cd /workspaces/github
      git status
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

