#!/usr/bin/env bash
# GitHub codespaces setup with parallel installation support.

# Check if parallel installation is requested
PARALLEL_MODE=${PARALLEL_MODE:-true}

# Help function
show_help() {
    echo "Dotfiles Installation Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --parallel     Enable parallel installation (default)"
    echo "  --sequential   Disable parallel installation (original mode)"
    echo "  --help, -h     Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  PARALLEL_MODE  Set to 'false' to disable parallel installation"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run with parallel mode (default)"
    echo "  $0 --sequential       # Run in original sequential mode"
    echo "  PARALLEL_MODE=false $0  # Run in sequential mode via env var"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --parallel)
            PARALLEL_MODE=true
            shift
            ;;
        --sequential)
            PARALLEL_MODE=false
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [[ "$PARALLEL_MODE" == "true" ]]; then
    # Source parallel installation framework
    source "$(dirname "$0")/scripts/parallel-install.sh"
    echo "🚀 Parallel installation mode enabled"
else
    # Original sequential mode
    INSTALL_START_TIME=$(date +%s)
    LOG_FILE=~/install.log
    declare -A TIMING_DATA

    # Initialize log file with header
    echo "=== Dotfiles Installation Log ===" > $LOG_FILE
    echo "Started: $(date)" >> $LOG_FILE
    echo "" >> $LOG_FILE
fi

# Helper function to log with timing
log_with_timing() {
    local operation="$1"
    local start_time="$2"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    TIMING_DATA["$operation"]=$duration
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $operation (${duration}s)" >> $LOG_FILE
}

# Helper function to start timing an operation
start_operation() {
    local operation="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔄 Starting: $operation" >> $LOG_FILE
    echo $(date +%s)
}

# Helper function to generate timing summary
generate_timing_summary() {
    local total_time=$(($(date +%s) - INSTALL_START_TIME))
    
    echo "" >> $LOG_FILE
    echo "=== TIMING SUMMARY ===" >> $LOG_FILE
    echo "Total installation time: ${total_time}s ($(($total_time / 60))m $(($total_time % 60))s)" >> $LOG_FILE
    echo "" >> $LOG_FILE
    echo "Operations by duration (longest first):" >> $LOG_FILE
    
    # Sort timing data by duration (longest first)
    for operation in "${!TIMING_DATA[@]}"; do
        echo "${TIMING_DATA[$operation]} $operation"
    done | sort -nr | while read duration op; do
        if [ $duration -ge 60 ]; then
            echo "  $op: ${duration}s ($(($duration / 60))m $(($duration % 60))s)" >> $LOG_FILE
        else
            echo "  $op: ${duration}s" >> $LOG_FILE
        fi
    done
    
    echo "" >> $LOG_FILE
    echo "=== PERFORMANCE INSIGHTS ===" >> $LOG_FILE
    
    # Categorize slow operations
    local slow_ops=()
    local medium_ops=()
    for operation in "${!TIMING_DATA[@]}"; do
        local duration=${TIMING_DATA[$operation]}
        if [ $duration -ge 60 ]; then
            slow_ops+=("$operation (${duration}s)")
        elif [ $duration -ge 10 ]; then
            medium_ops+=("$operation (${duration}s)")
        fi
    done
    
    if [ ${#slow_ops[@]} -gt 0 ]; then
        echo "🐌 Operations taking >60s:" >> $LOG_FILE
        printf '  %s\n' "${slow_ops[@]}" >> $LOG_FILE
        echo "" >> $LOG_FILE
    fi
    
    if [ ${#medium_ops[@]} -gt 0 ]; then
        echo "⚠️  Operations taking 10-60s:" >> $LOG_FILE
        printf '  %s\n' "${medium_ops[@]}" >> $LOG_FILE
        echo "" >> $LOG_FILE
    fi
    
    echo "Completed: $(date)" >> $LOG_FILE
}

function link_files() {
    local start_time=$(start_operation "Creating config directories")
    mkdir -p ~/.config
    log_with_timing "Creating config directories" $start_time
    
    # Link core config files
    start_time=$(start_operation "Linking gitconfig")
    if [ -e ~/.gitconfig ]; then
      rm ~/.gitconfig
    fi
    ln -s $(pwd)/gitconfig ~/.gitconfig
    log_with_timing "Linking gitconfig" $start_time
    
    start_time=$(start_operation "Linking gitignore_local")
    ln -sf $(pwd)/gitignore_local ~/.gitignore_local
    log_with_timing "Linking gitignore_local" $start_time
    
    # Link fish config (may take time due to removal)
    start_time=$(start_operation "Linking fish configuration")
    if [ -e ~/.config/fish ]; then
      rm -rf ~/.config/fish
    fi
    ln -sf $(pwd)/fish ~/.config/
    log_with_timing "Linking fish configuration" $start_time
    
    # Link application configs in batches for better timing granularity
    start_time=$(start_operation "Linking shell and editor configs")
    ln -sf $(pwd)/starship.toml ~/.config/
    ln -sf $(pwd)/nvim ~/.config/
    ln -sf $(pwd)/bat ~/.config/
    log_with_timing "Linking shell and editor configs" $start_time
    
    start_time=$(start_operation "Linking utility configs")
    ln -sf $(pwd)/vale.ini ~/.vale.ini
    ln -sf $(pwd)/prettierrc.json ~/.config/prettierrc.json
    ln -sf $(pwd)/gitmux.conf ~/.config/gitmux.conf
    ln -sf $(pwd)/tmuxinator ~/.config/tmuxinator
    ln -sf $(pwd)/neofetch ~/.config/neofetch
    log_with_timing "Linking utility configs" $start_time
    
    start_time=$(start_operation "Linking terminal tool configs")
    ln -sf $(pwd)/atuin ~/.config/atuin
    ln -sf $(pwd)/yazi ~/.config/yazi
    ln -sf $(pwd)/bottom ~/.config/bottom
    ln -sf $(pwd)/tmux ~/.config/tmux
    ln -sf $(pwd)/zellij ~/.config/zellij
    
    # Download zjstatus plugin for Zellij
    start_time=$(start_operation "Downloading zjstatus plugin for Zellij")
    mkdir -p ~/.config/zellij/plugins
    curl -L https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm \
      -o ~/.config/zellij/plugins/zjstatus.wasm 2>/dev/null || echo "Warning: Failed to download zjstatus plugin"
    log_with_timing "Downloading zjstatus plugin for Zellij" $start_time
    ln -sf $(pwd)/delta ~/.config/delta
    ln -sf $(pwd)/eza ~/.config/eza
    ln -sf $(pwd)/k9s ~/.config/k9s
    log_with_timing "Linking terminal tool configs" $start_time
    
    # Codespaces-specific configuration
    if [ -d /workspaces/github ]; then
      start_time=$(start_operation "Linking GitHub Codespaces Ruby tools")
      sudo ln -sf /workspaces/github/bin/rubocop /usr/local/bin/rubocop
      sudo ln -sf /workspaces/github/bin/srb /usr/local/bin/srb
      sudo ln -sf /workspaces/github/bin/bundle /usr/local/bin/bundle
      sudo ln -sf /workspaces/github/bin/solargraph /usr/local/bin/solargraph
      sudo ln -sf /workspaces/github/bin/safe-ruby /usr/local/bin/safe-ruby
      log_with_timing "Linking GitHub Codespaces Ruby tools" $start_time
      
      start_time=$(start_operation "Updating locale settings")
      sudo update-locale LANG=en_US.UTF-8 LC_TYPE=en_US.UTF-8 LC_ALL=en_US.UTF-8
      log_with_timing "Updating locale settings" $start_time
    fi
}

function install_software() {
    if [ -d /workspaces/github ]; then
      # Initial delay for system stability
      start_time=$(start_operation "Initial system wait (20s)")
      sleep 20
      log_with_timing "Initial system wait (20s)" $start_time
      
      # APT package installation (must be done first - dependencies for other tools)
      start_time=$(start_operation "Installing APT packages")
      sudo apt -o DPkg::Lock::Timeout=600 install build-essential python3-venv socat ncat ruby-dev jq tmux libfuse2 fuse software-properties-common most -y
      log_with_timing "Installing APT packages" $start_time
      
      start_time=$(start_operation "Removing conflicting APT packages")
      sudo apt remove bat ripgrep -y
      log_with_timing "Removing conflicting APT packages" $start_time
      
      if [[ "$PARALLEL_MODE" == "true" ]]; then
        # Parallel installation mode
        echo "🚀 Using parallel installation for major components..."
        
        # Start all parallel installation groups
        install_external_tools_parallel &
        parallel_externals_pid=$!
        
        install_cargo_packages_parallel &
        parallel_cargo_pid=$!
        
        # Wait for external tools to complete first (they're generally faster)
        wait $parallel_externals_pid
        if [ $? -ne 0 ]; then
          echo "❌ External tools installation failed" >> $LOG_FILE
        fi
        
        # Wait for cargo installations (these are the longest)
        wait $parallel_cargo_pid
        if [ $? -ne 0 ]; then
          echo "❌ Cargo installations failed" >> $LOG_FILE
        fi
        
        # Sequential operations that depend on cargo tools
        start_time=$(start_operation "Building bat cache")
        ~/.cargo/bin/bat cache --build
        log_with_timing "Building bat cache" $start_time
        
        # Setup software immediately after installation to avoid race conditions
        echo "🔧 Setting up installed software..."
        
        # Setup Atuin immediately after cargo installation
        start_time=$(start_operation "Logging into Atuin")
        echo "Log in to atuin"
        ~/.cargo/bin/atuin login -u $ATUIN_USERNAME -p $ATUIN_PASSWORD -k $ATUIN_KEY
        log_with_timing "Logging into Atuin" $start_time
        
        # Setup git tools immediately after installation
        start_time=$(start_operation "Cloning TPM (tmux plugin manager)")
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        log_with_timing "Cloning TPM (tmux plugin manager)" $start_time
        
        # Install tmux plugins immediately after TPM is available
        start_time=$(start_operation "Installing tmux plugins")
        ~/.tmux/plugins/tpm/scripts/install_plugins.sh
        log_with_timing "Installing tmux plugins" $start_time
        
      else
        # Original sequential mode
        # External tool installations
        start_time=$(start_operation "Installing Starship prompt")
        curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
        log_with_timing "Installing Starship prompt" $start_time
        
        start_time=$(start_operation "Installing Git Delta")
        curl -L https://github.com/dandavison/delta/releases/download/0.18.2/git-delta-musl_0.18.2_amd64.deb > ~/git-delta-musl_0.18.2_amd64.deb
        sudo dpkg -i ~/git-delta-musl_0.18.2_amd64.deb
        log_with_timing "Installing Git Delta" $start_time
        
        start_time=$(start_operation "Downloading Delta themes")
        wget --output-document ~/.config/delta-themes.gitconfig https://raw.githubusercontent.com/dandavison/delta/master/themes.gitconfig
        log_with_timing "Downloading Delta themes" $start_time
        
        start_time=$(start_operation "Installing yq")
        sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
        sudo chmod +x /usr/bin/yq
        log_with_timing "Installing yq" $start_time
        
        start_time=$(start_operation "Installing Protocol Buffers")
        PB_REL="https://github.com/protocolbuffers/protobuf/releases"
        curl -L $PB_REL/download/v25.1/protoc-25.1-linux-x86_64.zip > ~/protoc.zip
        unzip ~/protoc.zip -d $HOME/.local
        export PATH="$PATH:$HOME/.local/bin"
        log_with_timing "Installing Protocol Buffers" $start_time
        
        # Cargo installations (these tend to be slow)
        start_time=$(start_operation "Installing eza via cargo")
        cargo install eza
        log_with_timing "Installing eza via cargo" $start_time
        
        start_time=$(start_operation "Installing zoxide via cargo")
        cargo install --locked zoxide
        log_with_timing "Installing zoxide via cargo" $start_time
        
        start_time=$(start_operation "Installing ripgrep via cargo")
        cargo install ripgrep
        log_with_timing "Installing ripgrep via cargo" $start_time
        
        start_time=$(start_operation "Installing fd-find via cargo")
        cargo install fd-find
        log_with_timing "Installing fd-find via cargo" $start_time
        
        start_time=$(start_operation "Installing bat via cargo")
        cargo install --locked bat
        log_with_timing "Installing bat via cargo" $start_time
        
        start_time=$(start_operation "Installing atuin via cargo")
        cargo install --locked atuin
        log_with_timing "Installing atuin via cargo" $start_time
        
        start_time=$(start_operation "Installing tree-sitter-cli via cargo")
        cargo install --locked tree-sitter-cli
        log_with_timing "Installing tree-sitter-cli via cargo" $start_time
        
        start_time=$(start_operation "Installing pay-respects tools via cargo")
        cargo install --locked pay-respects
        cargo install --locked pay-respects-module-runtime-rules
        cargo install --locked pay-respects-module-request-ai
        log_with_timing "Installing pay-respects tools via cargo" $start_time
        
        # Bat cache build
        start_time=$(start_operation "Building bat cache")
        ~/.cargo/bin/bat cache --build
        log_with_timing "Building bat cache" $start_time
        
        # Setup software immediately after installation to avoid race conditions
        echo "🔧 Setting up installed software..."
        
        # Setup Atuin immediately after cargo installation
        start_time=$(start_operation "Logging into Atuin")
        echo "Log in to atuin"
        if [ -d /workspaces/github ]; then
          ~/.cargo/bin/atuin login -u $ATUIN_USERNAME -p $ATUIN_PASSWORD -k $ATUIN_KEY
        else
          /usr/local/cargo/bin/atuin login -u $ATUIN_USERNAME -p $ATUIN_PASSWORD -k $ATUIN_KEY
        fi
        log_with_timing "Logging into Atuin" $start_time
        
        # Setup git tools immediately after installation
        start_time=$(start_operation "Cloning TPM (tmux plugin manager)")
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        log_with_timing "Cloning TPM (tmux plugin manager)" $start_time
        
        # Install tmux plugins immediately after TPM is available
        start_time=$(start_operation "Installing tmux plugins")
        ~/.tmux/plugins/tpm/scripts/install_plugins.sh
        log_with_timing "Installing tmux plugins" $start_time
        
        # FZF installation
        start_time=$(start_operation "Installing FZF")
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
        log_with_timing "Installing FZF" $start_time
        
        # LazyGit installation
        start_time=$(start_operation "Installing LazyGit")
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit -D -t /usr/local/bin/
        log_with_timing "Installing LazyGit" $start_time
      fi
      
      # NPM installations (keep sequential for now)
      start_time=$(start_operation "Installing NPM global packages")
      npm install -g @fsouza/prettierd yaml-language-server vscode-langservers-extracted eslint_d prettier tree-sitter neovim
      log_with_timing "Installing NPM global packages" $start_time
    fi
    
    # Ruby gems installation
    start_time=$(start_operation "Installing Ruby gems")
    sudo gem install tmuxinator neovim-ruby-host
    log_with_timing "Installing Ruby gems" $start_time
    
    # Setup Neovim plugins immediately after neovim dependencies are installed
    start_time=$(start_operation "Syncing Neovim plugins (Lazy)")
    nvim --headless "+Lazy! sync" +qa
    log_with_timing "Syncing Neovim plugins (Lazy)" $start_time
    
    start_time=$(start_operation "Installing Mason tools in Neovim")
    nvim --headless "+MasonToolsInstallSync" +qa
    log_with_timing "Installing Mason tools in Neovim" $start_time
    
    start_time=$(start_operation "Downloading tmuxinator completions")
    curl -L https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.fish > ~/.config/fish/completions/
    log_with_timing "Downloading tmuxinator completions" $start_time
}

function setup_software() {
    # Final environment and shell setup (must run at the very end)
    if [ -d /workspaces/github ]; then
      start_time=$(start_operation "Changing default shell to fish")
      sudo chsh -s /usr/bin/fish vscode
      log_with_timing "Changing default shell to fish" $start_time
      
      start_time=$(start_operation "Checking git status in workspace")
      cd /workspaces/github
      git status
      log_with_timing "Checking git status in workspace" $start_time
    fi
}

echo '🔗 Starting file linking phase' >> $LOG_FILE
link_files_start=$(date +%s)
link_files
log_with_timing "🔗 File linking phase" $link_files_start

echo '💽 Starting software installation phase' >> $LOG_FILE
install_software_start=$(date +%s)
install_software
log_with_timing "💽 Software installation phase" $install_software_start

echo '👩‍🔧 Starting software configuration phase' >> $LOG_FILE
setup_software_start=$(date +%s)
setup_software
log_with_timing "👩‍🔧 Software configuration phase" $setup_software_start

echo '✅ Installation completed successfully!' >> $LOG_FILE
generate_timing_summary

