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
    # shellcheck disable=SC1091
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
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    TIMING_DATA["$operation"]=$duration
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $operation (${duration}s)" >> "$LOG_FILE"
}

# Helper function to start timing an operation
start_operation() {
    local operation="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔄 Starting: $operation" >> "$LOG_FILE"
    date +%s
}

# Helper function to generate timing summary
generate_timing_summary() {
    local total_time
    total_time=$(($(date +%s) - INSTALL_START_TIME))
    
    {
        echo ""
        echo "=== TIMING SUMMARY ==="
        echo "Total installation time: ${total_time}s ($((total_time / 60))m $((total_time % 60))s)"
        echo ""
        echo "Operations by duration (longest first):"
    } >> "$LOG_FILE"
    
    # Sort timing data by duration (longest first)
    for operation in "${!TIMING_DATA[@]}"; do
        echo "${TIMING_DATA[$operation]} $operation"
    done | sort -nr | while read -r duration op; do
        if [ "$duration" -ge 60 ]; then
            echo "  $op: ${duration}s ($((duration / 60))m $((duration % 60))s)" >> "$LOG_FILE"
        else
            echo "  $op: ${duration}s" >> "$LOG_FILE"
        fi
    done
    
    echo "" >> "$LOG_FILE"
    echo "=== PERFORMANCE INSIGHTS ===" >> "$LOG_FILE"
    
    # Categorize slow operations
    local slow_ops=()
    local medium_ops=()
    for operation in "${!TIMING_DATA[@]}"; do
        local duration=${TIMING_DATA[$operation]}
        if [ "$duration" -ge 60 ]; then
            slow_ops+=("$operation (${duration}s)")
        elif [ "$duration" -ge 10 ]; then
            medium_ops+=("$operation (${duration}s)")
        fi
    done
    
    if [ ${#slow_ops[@]} -gt 0 ]; then
        {
            echo "🐌 Operations taking >60s:"
            printf '  %s\n' "${slow_ops[@]}"
            echo ""
        } >> "$LOG_FILE"
    fi
    
    if [ ${#medium_ops[@]} -gt 0 ]; then
        {
            echo "⚠️  Operations taking 10-60s:"
            printf '  %s\n' "${medium_ops[@]}"
            echo ""
        } >> "$LOG_FILE"
    fi
    
    echo "Completed: $(date)" >> "$LOG_FILE"
}

function link_files() {
    local start_time
    start_time=$(start_operation "Creating config directories")
    mkdir -p ~/.config
    log_with_timing "Creating config directories" "$start_time"
    
    # Link core config files
    start_time=$(start_operation "Linking gitconfig")
    if [ -e ~/.gitconfig ]; then
      rm ~/.gitconfig
    fi
    ln -s "$(pwd)/gitconfig-github" ~/.gitconfig
    log_with_timing "Linking gitconfig" "$start_time"
    
    start_time=$(start_operation "Linking gitignore_local")
    ln -sf "$(pwd)/gitignore_local" ~/.gitignore_local
    log_with_timing "Linking gitignore_local" "$start_time"
    
    # Link fish config (may take time due to removal)
    start_time=$(start_operation "Linking fish configuration")
    if [ -e ~/.config/fish ]; then
      rm -rf ~/.config/fish
    fi
    ln -sf "$(pwd)/fish" ~/.config/
    log_with_timing "Linking fish configuration" "$start_time"
    
    # Link application configs in batches for better timing granularity
    start_time=$(start_operation "Linking shell and editor configs")
    ln -sf "$(pwd)/starship.toml" ~/.config/
    ln -sf "$(pwd)/nvim" ~/.config/
    ln -sf "$(pwd)/bat" ~/.config/
    log_with_timing "Linking shell and editor configs" "$start_time"
    
    start_time=$(start_operation "Linking utility configs")
    ln -sf "$(pwd)/vale.ini" ~/.vale.ini
    ln -sf "$(pwd)/prettierrc.json" ~/.config/prettierrc.json
    ln -sf "$(pwd)/gitmux.conf" ~/.config/gitmux.conf
    ln -sf "$(pwd)/tmuxinator" ~/.config/tmuxinator
    ln -sf "$(pwd)/neofetch" ~/.config/neofetch
    log_with_timing "Linking utility configs" "$start_time"
    
    start_time=$(start_operation "Linking terminal tool configs")
    ln -sf "$(pwd)/atuin" ~/.config/atuin
    ln -sf "$(pwd)/yazi" ~/.config/yazi
    ln -sf "$(pwd)/bottom" ~/.config/bottom
    ln -sf "$(pwd)/tmux" ~/.config/tmux
    ln -sf "$(pwd)/zellij" ~/.config/zellij
    
    ln -sf "$(pwd)/delta" ~/.config/delta
    ln -sf "$(pwd)/eza" ~/.config/eza
    ln -sf "$(pwd)/k9s" ~/.config/k9s
    
    # Make tmux indicator script available in PATH for tmux config
    if [ -d /workspaces/github ]; then
        sudo ln -sf "$(pwd)/scripts/tmux-background-install-indicator.sh" /usr/local/bin/
    fi
    
    log_with_timing "Linking terminal tool configs" "$start_time"
    
    # Codespaces-specific configuration - background non-critical operations
    if [ -d /workspaces/github ]; then
      start_time=$(start_operation "Linking GitHub Codespaces Ruby tools")
      sudo ln -sf /workspaces/github/bin/rubocop /usr/local/bin/rubocop
      sudo ln -sf /workspaces/github/bin/srb /usr/local/bin/srb
      sudo ln -sf /workspaces/github/bin/bundle /usr/local/bin/bundle
      sudo ln -sf /workspaces/github/bin/solargraph /usr/local/bin/solargraph
      sudo ln -sf /workspaces/github/bin/safe-ruby /usr/local/bin/safe-ruby
      log_with_timing "Linking GitHub Codespaces Ruby tools" "$start_time"
      
      # Background locale update as it's not immediately critical
      start_time=$(start_operation "Updating locale settings")
      (sudo update-locale LANG=en_US.UTF-8 LC_TYPE=en_US.UTF-8 LC_ALL=en_US.UTF-8) &
      locale_update_pid=$!
      log_with_timing "Updating locale settings" "$start_time"
      
      # Store locale update PID for later synchronization
      echo $locale_update_pid > ~/.dotfiles_locale_update.pid
    fi
}

function install_software() {
    if [ -d /workspaces/github ]; then
      # Reduce initial delay for faster startup
      start_time=$(start_operation "Initial system wait (5s)")
      sleep 5
      log_with_timing "Initial system wait (5s)" "$start_time"
      
      # APT package installation - split into essential and non-essential
      start_time=$(start_operation "Installing essential APT packages")
      sudo apt -o DPkg::Lock::Timeout=600 install tmux jq ruby-dev clang -y
      log_with_timing "Installing essential APT packages" "$start_time"
      
      # Install remaining APT packages and luarocks in background
      start_time=$(start_operation "Installing additional packages in background")
      (
        sudo apt -o DPkg::Lock::Timeout=600 install build-essential python3-venv socat ncat libfuse2 fuse software-properties-common most luarocks -y
        sudo luarocks install luacheck
      ) &
      additional_packages_pid=$!
      log_with_timing "Installing additional packages in background" "$start_time"
      
      # Remove conflicting APT packages in background to avoid blocking
      start_time=$(start_operation "Removing conflicting APT packages")
      (sudo apt remove bat ripgrep -y) &
      apt_remove_pid=$!
      log_with_timing "Removing conflicting APT packages" "$start_time"

      # Wait for apt remove to complete before continuing
      wait "$apt_remove_pid"
      
      if [[ "$PARALLEL_MODE" == "true" ]]; then
        # Parallel installation mode with fast track for essential tools
        echo "🚀 Using parallel installation with fast track for essential tools..."
        
        # Wait for clang to be available before using CC=clang
        wait $additional_packages_pid
        
        # FOREGROUND PRIORITY: Install atuin, zoxide, and tree-sitter in parallel before login
        start_time=$(start_operation "Foreground priority: atuin, zoxide, tree-sitter")
        echo "🎯 Installing atuin, zoxide, and tree-sitter in foreground (parallel)..."
        
        # Install the three critical tools in parallel in foreground
        CC=clang cargo install --locked atuin &
        atuin_pid=$!
        CC=clang cargo install --locked zoxide &
        zoxide_pid=$!
        CC=clang cargo install --locked tree-sitter-cli &
        tree_sitter_pid=$!
        
        # Wait for all three to complete
        wait $atuin_pid
        atuin_exit=$?
        wait $zoxide_pid
        zoxide_exit=$?
        wait $tree_sitter_pid
        tree_sitter_exit=$?
        
        if [ $atuin_exit -eq 0 ] && [ $zoxide_exit -eq 0 ] && [ $tree_sitter_exit -eq 0 ]; then
            echo "✅ All priority tools installed successfully!"
        else
            echo "⚠️ Some priority tools failed to install"
        fi
        
        log_with_timing "Foreground priority: atuin, zoxide, tree-sitter" "$start_time"
        
        # Setup atuin immediately if credentials are available
        if [ -n "$ATUIN_USERNAME" ] && [ -n "$ATUIN_PASSWORD" ] && [ -n "$ATUIN_KEY" ] && [ $atuin_exit -eq 0 ]; then
            start_time=$(start_operation "Atuin login setup")
            echo "🔐 Setting up Atuin login..."
            if ! ~/.cargo/bin/atuin status | grep -q "Username:"; then
                 ~/.cargo/bin/atuin login -u "$ATUIN_USERNAME" -p "$ATUIN_PASSWORD" -k "$ATUIN_KEY"
            else
                 echo "✅ Atuin already logged in"
            fi
            log_with_timing "Atuin login setup" "$start_time"
        fi
        
        # FAST TRACK: Setup essential tools immediately (tmux, nvim ready)
        start_time=$(start_operation "Fast track: Essential tool setup")
        
        # 1. Clone TPM immediately (user priority #1: tmux plugins)
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm &
        mkdir -p ~/.tmux/plugins
        ln -s ~/.config/tmux/plugins/tpm ~/.tmux/plugins/tpm
        tmp_pid=$!
        
        # 2. Install only tmuxinator immediately (user priority #2) - minimal Ruby setup
        sudo gem install tmuxinator &
        tmuxinator_pid=$!
        
        # 3. Wait for TPM and install plugins
        wait $tmp_pid
        ~/.tmux/plugins/tpm/scripts/install_plugins.sh
        
        # 4. Wait for tmuxinator 
        wait $tmuxinator_pid
        
        # 5. Start additional Ruby gems in background (neovim-ruby-host not immediately needed)
        (sudo gem install neovim-ruby-host > /dev/null 2>&1) &
        
        log_with_timing "Fast track: Essential tool setup" "$start_time"
        
        echo "✅ Essential tools ready! (atuin + zoxide + tree-sitter + tmux + plugins + tmuxinator + nvim configs)"
        echo "🚀 Starting background installations for remaining tools..."
        
        # Start external tools installation (now lower priority)
        install_external_tools_parallel &
        parallel_externals_pid=$!
        
        # Start Rust/Cargo installations in background (excluding the tools we already installed)
        (start_rust_background_installation_remaining) &
        rust_background_pid=$!
        
        # Start NPM packages installation in background
        (start_npm_background_installation) &
        npm_background_pid=$!
        
        # Start Neovim setup in background
        (start_neovim_background_setup) &
        neovim_background_pid=$!
        
        # Store the background process PIDs for tracking
        echo $rust_background_pid > ~/.dotfiles_rust_install.pid
        echo $npm_background_pid > ~/.dotfiles_npm_install.pid
        echo $neovim_background_pid > ~/.dotfiles_neovim_setup.pid
        
        # Start git status check as completely independent background process
        start_git_status_background &
        git_status_background_pid=$!
        echo $git_status_background_pid > ~/.dotfiles_git_status.pid
        
        # Wait for external tools to complete (now lower priority)
        if ! wait "$parallel_externals_pid"; then
          echo "❌ External tools installation failed" >> "$LOG_FILE"
        fi
        
        # Let user know about background installations
        echo ""
        echo "🦀 Rust tools are installing in the background (PID: $rust_background_pid)"
        echo "   📊 Priority: atuin & zoxide install first, then other tools"
        echo "📦 NPM packages are installing in the background (PID: $npm_background_pid)"
        echo "🔌 Neovim plugins are setting up in the background (PID: $neovim_background_pid)"
        echo "📊 Git status check running in background (PID: $git_status_background_pid)"
        echo "📄 Check Rust progress: tail -f ~/.dotfiles_rust_install.log"
        echo "📄 Check NPM progress: tail -f ~/.dotfiles_npm_install.log"
        echo "📄 Check Neovim progress: tail -f ~/.dotfiles_neovim_setup.log"
        echo "📄 Check Git status: tail -f ~/.dotfiles_git_status.log"
        echo "🔍 Check Rust status: $(dirname "$0")/scripts/check-rust-install.sh"
        echo "🔍 Check NPM status: $(dirname "$0")/scripts/check-npm-install.sh"
        echo "🔍 Check Neovim status: $(dirname "$0")/scripts/check-neovim-setup.sh"
        echo "⏳ Wait for Rust completion: wait $rust_background_pid"
        echo "⏳ Wait for NPM completion: wait $npm_background_pid"
        echo "⏳ Wait for Neovim completion: wait $neovim_background_pid"
        echo "⏳ Wait for Git status completion: wait $git_status_background_pid"
        echo ""
        
        # Refresh tmux status to show new indicators immediately
        "$(dirname "$0")/scripts/refresh-tmux-status.sh"
        
      else
        # Original sequential mode
        # External tool installations
        start_time=$(start_operation "Installing Starship prompt")
        curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
        log_with_timing "Installing Starship prompt" "$start_time"
        
        start_time=$(start_operation "Installing Git Delta")
        curl -L https://github.com/dandavison/delta/releases/download/0.18.2/git-delta-musl_0.18.2_amd64.deb > ~/git-delta-musl_0.18.2_amd64.deb
        sudo dpkg -i ~/git-delta-musl_0.18.2_amd64.deb
        log_with_timing "Installing Git Delta" "$start_time"
        
        start_time=$(start_operation "Downloading Delta themes")
        wget --output-document ~/.config/delta-themes.gitconfig https://raw.githubusercontent.com/dandavison/delta/master/themes.gitconfig
        log_with_timing "Downloading Delta themes" "$start_time"
        
        start_time=$(start_operation "Installing yq")
        sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
        sudo chmod +x /usr/bin/yq
        log_with_timing "Installing yq" "$start_time"
        
        start_time=$(start_operation "Installing Protocol Buffers")
        PB_REL="https://github.com/protocolbuffers/protobuf/releases"
        curl -L $PB_REL/download/v25.1/protoc-25.1-linux-x86_64.zip > ~/protoc.zip
        unzip ~/protoc.zip -d "$HOME"/.local
        export PATH="$PATH:$HOME/.local/bin"
        log_with_timing "Installing Protocol Buffers" "$start_time"
        
        # Wait for clang to be available before using CC=clang
        wait $additional_packages_pid
        
        # Cargo installations (these tend to be slow)
        start_time=$(start_operation "Installing eza via cargo")
        CC=clang cargo install eza
        log_with_timing "Installing eza via cargo" "$start_time"
        
        start_time=$(start_operation "Installing zoxide via cargo")
        CC=clangcargo install --locked zoxide
        log_with_timing "Installing zoxide via cargo" "$start_time"
        
        start_time=$(start_operation "Installing ripgrep via cargo")
        CC=clang cargo install ripgrep
        log_with_timing "Installing ripgrep via cargo" "$start_time"
        
        start_time=$(start_operation "Installing fd-find via cargo")
        CC=clang cargo install fd-find
        log_with_timing "Installing fd-find via cargo" "$start_time"
        
        start_time=$(start_operation "Installing bat via cargo")
        CC=clang cargo install --locked bat
        log_with_timing "Installing bat via cargo" "$start_time"
        
        start_time=$(start_operation "Installing atuin via cargo")
        CC=clang cargo install --locked atuin
        log_with_timing "Installing atuin via cargo" "$start_time"
        
        start_time=$(start_operation "Installing tree-sitter-cli via cargo")
        CC=clang cargo install --locked tree-sitter-cli
        log_with_timing "Installing tree-sitter-cli via cargo" "$start_time"
        
        start_time=$(start_operation "Installing pay-respects tools via cargo")
        CC=clang cargo install --locked pay-respects
        CC=clang cargo install --locked pay-respects-module-runtime-rules
        CC=clang cargo install --locked pay-respects-module-request-ai
        log_with_timing "Installing pay-respects tools via cargo" "$start_time"
        
        start_time=$(start_operation "Installing zellij via cargo")
        CC=clang cargo install --locked zellij
        log_with_timing "Installing zellij via cargo" "$start_time"
        
        start_time=$(start_operation "Installing bottom tools via cargo")
        CC=clang cargo install --locked bottom
        log_with_timing "Installing bottom tools via cargo" "$start_time"

        start_time=$(start_operation "Installing cloudflare-speed-cli via cargo")
        CC=clang cargo install --git https://github.com/kavehtehrani/cloudflare-speed-cli --features tui
        log_with_timing "Installing cloudflare-speed-cli via cargo" "$start_time"

        # Bat cache build
        start_time=$(start_operation "Building bat cache")
        ~/.cargo/bin/bat cache --build
        log_with_timing "Building bat cache" "$start_time"
        
        # Setup software immediately after installation to avoid race conditions
        echo "🔧 Setting up installed software..."
        
        # Setup Atuin immediately after cargo installation
        start_time=$(start_operation "Logging into Atuin")
        echo "Log in to atuin"
        if [ -d /workspaces/github ]; then
          if ! ~/.cargo/bin/atuin status | grep -q "Username:"; then
            ~/.cargo/bin/atuin login -u "$ATUIN_USERNAME" -p "$ATUIN_PASSWORD" -k "$ATUIN_KEY"
          else
            echo "✅ Atuin already logged in"
          fi
        else
          if ! /usr/local/cargo/bin/atuin status | grep -q "Username:"; then
            /usr/local/cargo/bin/atuin login -u "$ATUIN_USERNAME" -p "$ATUIN_PASSWORD" -k "$ATUIN_KEY"
          else
            echo "✅ Atuin already logged in"
          fi
        fi
        log_with_timing "Logging into Atuin" "$start_time"
        
        # Setup git tools immediately after installation
        start_time=$(start_operation "Cloning TPM (tmux plugin manager)")
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        log_with_timing "Cloning TPM (tmux plugin manager)" "$start_time"
        
        # Install tmux plugins immediately after TPM is available
        start_time=$(start_operation "Installing tmux plugins")
        ~/.tmux/plugins/tpm/scripts/install_plugins.sh
        log_with_timing "Installing tmux plugins" "$start_time"
        
        # FZF installation
        start_time=$(start_operation "Installing FZF")
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
        log_with_timing "Installing FZF" "$start_time"
        
        # LazyGit installation
        start_time=$(start_operation "Installing LazyGit")
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit -D -t /usr/local/bin/
        log_with_timing "Installing LazyGit" "$start_time"
        
        # Install Ruby gems in parallel
        start_time=$(start_operation "Installing Ruby gems in parallel")
        install_ruby_gems_parallel
        log_with_timing "Installing Ruby gems in parallel" "$start_time"
      fi
      
      # Sequential installations removed - now handled in background or parallel
      
    fi
    
    # Most software setup now handled in background processes
    # Only essential immediate setup remains in foreground
}

function setup_software() {
    # Final environment and shell setup (must run at the very end)
    if [ -d /workspaces/github ]; then
      # Change shell is the only critical operation that must complete
      start_time=$(start_operation "Changing default shell to fish")
      sudo chsh -s /usr/bin/fish vscode
      log_with_timing "Changing default shell to fish" "$start_time"
      
      # Wait for locale update from linking phase if it's still running
      if [ -f ~/.dotfiles_locale_update.pid ]; then
        locale_pid=$(cat ~/.dotfiles_locale_update.pid)
        if kill -0 "$locale_pid" 2>/dev/null; then
          echo "⏳ Waiting for locale update to complete..."
          wait "$locale_pid"
        fi
        rm -f ~/.dotfiles_locale_update.pid
      fi
    fi
}

function start_rust_background_installation() {
    local rust_log=~/.dotfiles_rust_install.log
    local rust_pid_file=~/.dotfiles_rust_install.pid
    
    # Log the start of Rust installation
    {
        echo "🦀 Starting Rust tools installation in background at $(date)"
        echo "PID: $$"
        echo ""
    } > "$rust_log"
    
    # Install Rust/Cargo packages in background
    {
        # Set LOG_FILE for the parallel installation functions
        # shellcheck disable=SC2030,SC2031
        export LOG_FILE=$rust_log
        
        echo "Installing Rust/Cargo packages..." >> "$rust_log"
        install_cargo_packages_background
        cargo_exit_code=$?
        
        if [ $cargo_exit_code -eq 0 ]; then
            {
                echo "✅ Cargo installations completed successfully"
                
                # Build bat cache after successful installation
                echo "Building bat cache..."
                ~/.cargo/bin/bat cache --build
                
                # Note: Atuin setup is now handled immediately in the priority batch
                # within install_cargo_packages_background function
                
                echo "🎉 All Rust tools installation completed successfully at $(date)"
            } >> "$rust_log"
        else
            echo "❌ Cargo installations failed with exit code $cargo_exit_code" >> "$rust_log"
        fi
        
        # Remove PID file when done and refresh tmux status
        rm -f $rust_pid_file
        "$(dirname "$0")/scripts/refresh-tmux-status.sh"
        
    } &
    
    # Store the background process PID
    echo $! > $rust_pid_file
}

function start_rust_background_installation_remaining() {
    local rust_log=~/.dotfiles_rust_install.log
    local rust_pid_file=~/.dotfiles_rust_install.pid
    
    # Log the start of Rust installation (remaining tools)
    {
        echo "🦀 Starting remaining Rust tools installation in background at $(date)"
        echo "PID: $$"
        echo "Note: atuin, zoxide, tree-sitter already installed in foreground"
        echo ""
    } > "$rust_log"
    
    # Install remaining Rust/Cargo packages in background
    {
        # Set LOG_FILE for the parallel installation functions
        # shellcheck disable=SC2030,SC2031
        export LOG_FILE=$rust_log
        
        echo "Installing remaining Rust/Cargo packages..." >> "$rust_log"
        install_cargo_packages_background_remaining
        cargo_exit_code=$?
        
        if [ $cargo_exit_code -eq 0 ]; then
            {
                echo "✅ Remaining cargo installations completed successfully"
                
                # Build bat cache after successful installation
                echo "Building bat cache..."
                ~/.cargo/bin/bat cache --build
                
                echo "🎉 All remaining Rust tools installation completed successfully at $(date)"
            } >> "$rust_log"
        else
            echo "❌ Remaining cargo installations failed with exit code $cargo_exit_code" >> "$rust_log"
        fi
        
        # Remove PID file when done and refresh tmux status
        rm -f $rust_pid_file
        "$(dirname "$0")/scripts/refresh-tmux-status.sh"
        
    } &
    
    # Store the background process PID
    echo $! > $rust_pid_file
}

function start_npm_background_installation() {
    local npm_log=~/.dotfiles_npm_install.log
    local npm_pid_file=~/.dotfiles_npm_install.pid
    
    # Log the start of NPM installation
    echo "📦 Starting NPM packages installation in background at $(date)" > $npm_log
    echo "PID: $$" >> $npm_log
    echo "" >> $npm_log
    
    # Install NPM packages in background
    {
        echo "Installing NPM global packages..." >> $npm_log
        
        if [ -d /workspaces/github ]; then
            npm install -g @fsouza/prettierd yaml-language-server vscode-langservers-extracted eslint_d prettier tree-sitter neovim >> $npm_log 2>&1
            npm_exit_code=$?
            
            if [ $npm_exit_code -eq 0 ]; then
                echo "✅ NPM packages installation completed successfully" >> $npm_log
                echo "🎉 All NPM packages installed successfully at $(date)" >> $npm_log
            else
                echo "❌ NPM packages installation failed with exit code $npm_exit_code" >> $npm_log
            fi
        else
            echo "⚠️  Not in Codespaces environment - skipping NPM installation" >> $npm_log
        fi
        
        # Remove PID file when done and refresh tmux status
        rm -f $npm_pid_file
        "$(dirname "$0")/scripts/refresh-tmux-status.sh"
        
    } &
    
    # Store the background process PID
    echo $! > $npm_pid_file
}

function install_ruby_gems_parallel() {
    if [ -d /workspaces/github ]; then
        echo "Installing Ruby gems in parallel..."
        
        # Install gems in parallel using background processes
        sudo gem install tmuxinator &
        tmuxinator_pid=$!
        
        sudo gem install neovim-ruby-host &
        neovim_ruby_pid=$!
        
        # Wait for both installations to complete
        wait $tmuxinator_pid
        tmuxinator_exit=$?
        
        wait $neovim_ruby_pid  
        neovim_ruby_exit=$?
        
        if [ $tmuxinator_exit -eq 0 ] && [ $neovim_ruby_exit -eq 0 ]; then
            echo "✅ All Ruby gems installed successfully"
        else
            echo "⚠️  Some Ruby gem installations may have failed"
        fi
    fi
}

function start_neovim_background_setup() {
    local neovim_log=~/.dotfiles_neovim_setup.log
    local neovim_pid_file=~/.dotfiles_neovim_setup.pid
    
    # Log the start of Neovim setup
    echo "🔌 Starting Neovim plugins setup in background at $(date)" > $neovim_log
    echo "PID: $$" >> $neovim_log
    echo "" >> $neovim_log
    
    # Setup Neovim in background
    {
        echo "Syncing Neovim plugins (Lazy)..." >> $neovim_log
        nvim --headless "+Lazy! sync" +qa >> $neovim_log 2>&1
        lazy_exit_code=$?
        
        if [ $lazy_exit_code -eq 0 ]; then
            echo "✅ Lazy sync completed successfully" >> $neovim_log
        else
            echo "⚠️  Lazy sync failed with exit code $lazy_exit_code" >> $neovim_log
        fi
        
        echo "Installing Mason tools in Neovim..." >> $neovim_log
        nvim --headless "+MasonToolsInstallSync" +qa >> $neovim_log 2>&1
        mason_exit_code=$?
        
        if [ $mason_exit_code -eq 0 ]; then
            echo "✅ Mason tools installation completed successfully" >> $neovim_log
        else
            echo "⚠️  Mason tools installation failed with exit code $mason_exit_code" >> $neovim_log
        fi
        
        echo "Downloading tmuxinator completions..." >> $neovim_log
        curl -L https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.fish > ~/.config/fish/completions/tmuxinator.fish >> $neovim_log 2>&1
        curl_exit_code=$?
        
        if [ $curl_exit_code -eq 0 ]; then
            echo "✅ Tmuxinator completions downloaded successfully" >> $neovim_log
        else
            echo "⚠️  Tmuxinator completions download failed with exit code $curl_exit_code" >> $neovim_log
        fi
        
        if [ $lazy_exit_code -eq 0 ] && [ $mason_exit_code -eq 0 ] && [ $curl_exit_code -eq 0 ]; then
            echo "🎉 All Neovim setup completed successfully at $(date)" >> $neovim_log
        else
            echo "⚠️  Some Neovim setup steps failed - check logs above" >> $neovim_log
        fi
        
        # Remove PID file when done and refresh tmux status
        rm -f $neovim_pid_file
        "$(dirname "$0")/scripts/refresh-tmux-status.sh"
        
    } &
    
    # Store the background process PID
    echo $! > $neovim_pid_file
}

function start_git_status_background() {
    local git_log=~/.dotfiles_git_status.log
    local git_pid_file=~/.dotfiles_git_status.pid
    
    # Log the start of Git status check
    echo "📊 Starting Git status check in background at $(date)" > $git_log
    echo "PID: $$" >> $git_log
    echo "" >> $git_log
    
    # Run git status in background
    {
        if [ -d /workspaces/github ]; then
            echo "Checking git status in /workspaces/github..." >> "$git_log"
            cd /workspaces/github || exit
            git --no-pager status >> "$git_log" 2>&1
            git_exit_code=$?
            
            if [ $git_exit_code -eq 0 ]; then
                echo "✅ Git status check completed successfully" >> "$git_log"
            else
                echo "⚠️  Git status check failed with exit code $git_exit_code" >> "$git_log"
            fi
            
            echo "🎉 Git status check completed at $(date)" >> "$git_log"
        else
            echo "⚠️  Not in Codespaces environment - skipping git status check" >> "$git_log"
        fi
        
        # Remove PID file when done and refresh tmux status
        rm -f $git_pid_file
        "$(dirname "$0")/scripts/refresh-tmux-status.sh"
        
    } &
    
    # Store the background process PID
    echo $! > $git_pid_file
}

# shellcheck disable=SC2031
echo '🔗 Starting file linking phase' >> "$LOG_FILE"
link_files_start=$(date +%s)
link_files
log_with_timing "🔗 File linking phase" "$link_files_start"

# shellcheck disable=SC2031
echo '💽 Starting software installation phase' >> "$LOG_FILE"
install_software_start=$(date +%s)
install_software
log_with_timing "💽 Software installation phase" "$install_software_start"

# shellcheck disable=SC2031
echo '👩‍🔧 Starting software configuration phase' >> "$LOG_FILE"
setup_software_start=$(date +%s)
setup_software
log_with_timing "👩‍🔧 Software configuration phase" "$setup_software_start"

# shellcheck disable=SC2031
echo '✅ Installation completed successfully!' >> "$LOG_FILE"
generate_timing_summary

