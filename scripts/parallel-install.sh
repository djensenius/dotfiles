#!/usr/bin/env bash
# Parallel installation enhancement for dotfiles setup
# This script adds parallel execution capabilities to speed up installation

# Global variables for timing and parallel execution
INSTALL_START_TIME=$(date +%s)
LOG_FILE=~/install.log
declare -A TIMING_DATA
declare -A PARALLEL_PIDS
declare -A PARALLEL_LOGS

# Initialize log file with header
echo "=== Dotfiles Parallel Installation Log ===" > $LOG_FILE
echo "Started: $(date)" >> $LOG_FILE
echo "" >> $LOG_FILE

# Helper function to run operations in parallel
run_parallel() {
    local operation_name="$1"
    local command="$2"
    local log_file="/tmp/parallel_${operation_name//[^a-zA-Z0-9]/_}.log"
    
    PARALLEL_LOGS["$operation_name"]="$log_file"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 Starting parallel: $operation_name" >> $LOG_FILE
    
    # Run command in background, capturing both stdout and stderr
    (
        start_time=$(date +%s)
        echo "=== $operation_name started at $(date) ===" > "$log_file"
        eval "$command" >> "$log_file" 2>&1
        exit_code=$?
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "=== $operation_name completed in ${duration}s with exit code $exit_code ===" >> "$log_file"
        exit $exit_code
    ) &
    
    PARALLEL_PIDS["$operation_name"]=$!
}

# Wait for parallel operations to complete
wait_for_parallel() {
    local operations=("$@")
    local failed_operations=()
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏳ Waiting for ${#operations[@]} parallel operations to complete..." >> $LOG_FILE
    
    for operation in "${operations[@]}"; do
        local pid=${PARALLEL_PIDS["$operation"]}
        local log_file=${PARALLEL_LOGS["$operation"]}
        
        if wait "$pid"; then
            # Extract timing from log file
            local duration
            duration=$(grep "completed in" "$log_file" | grep -o '[0-9]\+s' | head -1 | sed 's/s//')
            if [[ -n "$duration" ]]; then
                TIMING_DATA["$operation"]=$duration
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $operation completed (${duration}s)" >> $LOG_FILE
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $operation completed" >> $LOG_FILE
            fi
            
            # Append operation log to main log
            {
                echo ""
                echo "--- $operation output ---"
                cat "$log_file"
                echo "--- end $operation output ---"
                echo ""
            } >> "$LOG_FILE"
        else
            failed_operations+=("$operation")
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $operation FAILED" >> "$LOG_FILE"
            
            # Still append log for debugging
            {
                echo ""
                echo "--- $operation FAILED output ---"
                cat "$log_file"
                echo "--- end $operation FAILED output ---"
                echo ""
            } >> "$LOG_FILE"
        fi
        
        # Clean up log file
        rm -f "$log_file"
        unset 'PARALLEL_PIDS[$operation]'
        unset 'PARALLEL_LOGS[$operation]'
    done
    
    if [[ ${#failed_operations[@]} -gt 0 ]]; then
        echo "❌ The following operations failed: ${failed_operations[*]}" >> $LOG_FILE
        return 1
    fi
    
    return 0
}

# Enhanced cargo installation with parallel execution and priority ordering
install_cargo_packages_parallel() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 Starting parallel cargo installations with priority ordering..." >> $LOG_FILE
    
    # PRIORITY BATCH 1: Essential tools needed soonest (atuin, zoxide)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting priority batch 1: Essential shell tools" >> $LOG_FILE
    run_parallel "cargo_atuin" "AWS_LC_SYS_CMAKE_BUILDER=1 CC=gcc cargo install --locked atuin"
    run_parallel "cargo_zoxide" "CC=gcc cargo install --locked zoxide"
    
    # Wait for priority tools first
    local priority_operations=("cargo_atuin" "cargo_zoxide")
    if wait_for_parallel "${priority_operations[@]}"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Priority batch 1 completed - essential shell tools ready" >> $LOG_FILE
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Priority batch 1 failed" >> $LOG_FILE
    fi
    
    # PRIORITY BATCH 2: Common file tools
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting priority batch 2: File management tools" >> $LOG_FILE
    run_parallel "cargo_eza" "CC=gcc cargo install eza"
    run_parallel "cargo_ripgrep" "CC=gcc cargo install ripgrep"
    run_parallel "cargo_fd_find" "CC=gcc cargo install fd-find"
    run_parallel "cargo_bat" "CC=gcc cargo install --locked bat"
    
    # PRIORITY BATCH 3: Development tools
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting priority batch 3: Development tools" >> $LOG_FILE
    run_parallel "cargo_tree_sitter" "CC=gcc cargo install --locked tree-sitter-cli"
    run_parallel "cargo_bottom" "CC=gcc cargo install --locked bottom"
    run_parallel "cargo_zellij" "AWS_LC_SYS_CMAKE_BUILDER=1 CC=gcc cargo install --locked zellij"
    run_parallel "cargo_cfspeed" "AWS_LC_SYS_CMAKE_BUILDER=1 CC=gcc cargo install --git https://github.com/kavehtehrani/cloudflare-speed-cli --features tui"
    
    # PRIORITY BATCH 4: Optional tools (lowest priority)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting priority batch 4: Optional tools" >> $LOG_FILE
    run_parallel "cargo_pay_respects" "
        CC=gcc cargo install --locked pay-respects &&
        CC=gcc cargo install --locked pay-respects-module-runtime-rules &&
        CC=gcc cargo install --locked pay-respects-module-request-ai
    "
    
    # Wait for all remaining installations to complete
    local remaining_operations=(
        "cargo_eza" "cargo_ripgrep" "cargo_fd_find" "cargo_bat"
        "cargo_tree_sitter" "cargo_bottom" "cargo_zellij" "cargo_cfspeed" "cargo_pay_respects"
    )
    
    if wait_for_parallel "${remaining_operations[@]}"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ All cargo installations completed successfully" >> "$LOG_FILE"
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Some cargo installations failed" >> "$LOG_FILE"
        return 1
    fi
}

# Cargo installation without Atuin setup (for background installation) with priority ordering
install_cargo_packages_background() {
    # Use the same LOG_FILE that was set up by the background function
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 Starting parallel cargo installations with priority ordering..." >> $LOG_FILE
    
    # PRIORITY BATCH 1: Essential tools needed soonest (atuin, zoxide)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting priority batch 1: Essential shell tools" >> $LOG_FILE
    run_parallel "cargo_atuin" "AWS_LC_SYS_CMAKE_BUILDER=1 CC=gcc cargo install --locked atuin"
    run_parallel "cargo_zoxide" "CC=gcc cargo install --locked zoxide"
    
    # Wait for priority tools first and make them available immediately
    local priority_operations=("cargo_atuin" "cargo_zoxide")
    if wait_for_parallel "${priority_operations[@]}"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Priority batch 1 completed - essential shell tools ready" >> $LOG_FILE
        
        # Immediately setup atuin if credentials are available (don't wait for other tools)
        if [ -n "$ATUIN_USERNAME" ] && [ -n "$ATUIN_PASSWORD" ] && [ -n "$ATUIN_KEY" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔧 Setting up Atuin immediately after installation..." >> "$LOG_FILE"
            if ! ~/.cargo/bin/atuin status | grep -q "Username:"; then
                if ~/.cargo/bin/atuin login -u "$ATUIN_USERNAME" -p "$ATUIN_PASSWORD" -k "$ATUIN_KEY" >> "$LOG_FILE" 2>&1; then
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Atuin login completed immediately" >> "$LOG_FILE"
                else
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  Atuin login failed - check credentials" >> "$LOG_FILE"
                fi
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Atuin already logged in" >> "$LOG_FILE"
            fi
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Priority batch 1 failed" >> $LOG_FILE
    fi
    
    # PRIORITY BATCH 2: Common file tools
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting priority batch 2: File management tools" >> $LOG_FILE
    run_parallel "cargo_eza" "CC=gcc cargo install eza"
    run_parallel "cargo_ripgrep" "CC=gcc cargo install ripgrep"
    run_parallel "cargo_fd_find" "CC=gcc cargo install fd-find"
    run_parallel "cargo_bat" "CC=gcc cargo install --locked bat"
    
    # PRIORITY BATCH 3: Development tools
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting priority batch 3: Development tools" >> $LOG_FILE
    run_parallel "cargo_tree_sitter" "CC=gcc cargo install --locked tree-sitter-cli"
    run_parallel "cargo_bottom" "CC=gcc cargo install --locked bottom"
    run_parallel "cargo_zellij" "AWS_LC_SYS_CMAKE_BUILDER=1 CC=gcc cargo install --locked zellij"
    run_parallel "cargo_cfspeed" "AWS_LC_SYS_CMAKE_BUILDER=1 CC=gcc cargo install --git https://github.com/kavehtehrani/cloudflare-speed-cli --features tui"
    
    # PRIORITY BATCH 4: Optional tools (lowest priority)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting priority batch 4: Optional tools" >> $LOG_FILE
    run_parallel "cargo_pay_respects" "
        CC=gcc cargo install --locked pay-respects &&
        CC=gcc cargo install --locked pay-respects-module-runtime-rules &&
        CC=gcc cargo install --locked pay-respects-module-request-ai
    "
    
    # Wait for all remaining installations to complete
    local remaining_operations=(
        "cargo_eza" "cargo_ripgrep" "cargo_fd_find" "cargo_bat"
        "cargo_tree_sitter" "cargo_bottom" "cargo_zellij" "cargo_cfspeed" "cargo_pay_respects"
    )
    
    if wait_for_parallel "${remaining_operations[@]}"; then
        {
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ All cargo installations completed successfully"
            
            # Build bat cache after successful installation
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔧 Building bat cache..."
            ~/.cargo/bin/bat cache --build
        } >> "$LOG_FILE" 2>&1
        
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Some cargo installations failed" >> "$LOG_FILE"
        return 1
    fi
}

# Cargo installation for remaining tools (atuin, zoxide, tree-sitter already installed)
install_cargo_packages_background_remaining() {
    # Use the same LOG_FILE that was set up by the background function
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 Starting remaining cargo installations (atuin, zoxide, tree-sitter already done)..." >> $LOG_FILE
    
    # PRIORITY BATCH 2: Common file tools
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting file management tools" >> $LOG_FILE
    run_parallel "cargo_eza" "CC=gcc cargo install eza"
    run_parallel "cargo_ripgrep" "CC=gcc cargo install ripgrep"
    run_parallel "cargo_fd_find" "CC=gcc cargo install fd-find"
    run_parallel "cargo_bat" "CC=gcc cargo install --locked bat"
    
    # PRIORITY BATCH 3: Development tools
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting development tools" >> $LOG_FILE
    run_parallel "cargo_bottom" "CC=gcc cargo install --locked bottom"
    run_parallel "cargo_zellij" "AWS_LC_SYS_CMAKE_BUILDER=1 CC=gcc cargo install --locked zellij"
    run_parallel "cargo_cfspeed" "AWS_LC_SYS_CMAKE_BUILDER=1 CC=gcc cargo install --git https://github.com/kavehtehrani/cloudflare-speed-cli --features tui"
    
    # PRIORITY BATCH 4: Optional tools (lowest priority)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 Starting optional tools" >> $LOG_FILE
    run_parallel "cargo_pay_respects" "
        CC=gcc cargo install --locked pay-respects &&
        CC=gcc cargo install --locked pay-respects-module-runtime-rules &&
        CC=gcc cargo install --locked pay-respects-module-request-ai
    "
    
    # Wait for all remaining installations to complete
    local remaining_operations=(
        "cargo_eza" "cargo_ripgrep" "cargo_fd_find" "cargo_bat"
        "cargo_bottom" "cargo_zellij" "cargo_cfspeed" "cargo_pay_respects"
    )
    
    if wait_for_parallel "${remaining_operations[@]}"; then
        {
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ All remaining cargo installations completed successfully"
            
            # Build bat cache after successful installation
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔧 Building bat cache..."
            ~/.cargo/bin/bat cache --build
        } >> "$LOG_FILE" 2>&1
        
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Some remaining cargo installations failed" >> "$LOG_FILE"
        return 1
    fi
}

# Parallel external tool downloads
install_external_tools_parallel() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 Starting parallel external tool downloads..." >> $LOG_FILE
    
    # Start downloads in parallel
    run_parallel "starship_install" "curl -sS https://starship.rs/install.sh | sudo sh -s -- -y"
    
    run_parallel "git_delta_install" "
        curl -L https://github.com/dandavison/delta/releases/download/0.18.2/git-delta-musl_0.18.2_amd64.deb > ~/git-delta-musl_0.18.2_amd64.deb &&
        sudo dpkg -i ~/git-delta-musl_0.18.2_amd64.deb
    "
    
    run_parallel "delta_themes_download" "
        wget --output-document ~/.config/delta-themes.gitconfig https://raw.githubusercontent.com/dandavison/delta/master/themes.gitconfig
    "
    
    run_parallel "yq_install" "
        sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&
        sudo chmod +x /usr/bin/yq
    "
    
    run_parallel "protobuf_install" "
        PB_REL='https://github.com/protocolbuffers/protobuf/releases' &&
        curl -L \$PB_REL/download/v25.1/protoc-25.1-linux-x86_64.zip > ~/protoc.zip &&
        unzip ~/protoc.zip -d \$HOME/.local &&
        export PATH=\"\$PATH:\$HOME/.local/bin\"
    "
    
    run_parallel "fzf_install" "
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf &&
        ~/.fzf/install --all
    "
    
    run_parallel "lazygit_install" "
        LAZYGIT_VERSION=\$(curl -s 'https://api.github.com/repos/jesseduffield/lazygit/releases/latest' | grep -Po '\"tag_name\": *\"v\K[^\"]*') &&
        curl -Lo lazygit.tar.gz \"https://github.com/jesseduffield/lazygit/releases/download/v\${LAZYGIT_VERSION}/lazygit_\${LAZYGIT_VERSION}_Linux_x86_64.tar.gz\" &&
        tar xf lazygit.tar.gz lazygit &&
        sudo install lazygit -D -t /usr/local/bin/
    "
    run_parallel "ruby_lsp_install" "
      if [ -d '/workspaces/github' ]; then
        export RAILS_ROOT='/workspaces/github'
        export PATH=\$RAILS_ROOT/vendor/ruby/\'$(/workspaces/github/config/ruby-version)\'/bin:\$PATH
        gem install ruby-lsp
        gem install rainbow regexp_parser unicode-display_width rubocop-ast ruby-progressbar lint_roller parallel
      fi
    "
    
    # Wait for all downloads to complete
    local download_operations=(
        "starship_install" "git_delta_install" "delta_themes_download" 
        "yq_install" "protobuf_install" "fzf_install" "lazygit_install"
    )
    
    if wait_for_parallel "${download_operations[@]}"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ All external tool downloads completed successfully" >> $LOG_FILE
        
        # Setup git tools immediately after external tools complete
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔧 Setting up git tools after external tool installation..." >> $LOG_FILE
        tpm_start_time=$(date +%s)
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || echo "TPM already cloned"
        tpm_end_time=$(date +%s)
        TIMING_DATA["Cloning TPM (tmux plugin manager)"]=$((tpm_end_time - tpm_start_time))
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Git tools setup completed" >> $LOG_FILE
        
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Some external tool downloads failed" >> $LOG_FILE
        return 1
    fi
}

# Parallel git operations
setup_git_tools_parallel() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 Starting parallel git tool setup..." >> $LOG_FILE
    
    run_parallel "tpm_clone" "git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    
    # Wait for git operations
    local git_operations=("tpm_clone")
    
    if wait_for_parallel "${git_operations[@]}"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ All git tools setup completed successfully" >> $LOG_FILE
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Some git tools setup failed" >> $LOG_FILE
        return 1
    fi
}

# Helper function to log with timing (from original script)
log_with_timing() {
    local operation="$1"
    local start_time="$2"
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    TIMING_DATA["$operation"]=$duration
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $operation (${duration}s)" >> "$LOG_FILE"
}

# Helper function to start timing an operation (from original script)
start_operation() {
    local operation="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔄 Starting: $operation" >> "$LOG_FILE"
    date +%s
}

# Generate timing summary with parallel operation insights
generate_timing_summary() {
    local total_time
    total_time=$(($(date +%s) - INSTALL_START_TIME))
    
    {
        echo ""
        echo "=== PARALLEL INSTALLATION TIMING SUMMARY ==="
        echo "Total installation time: ${total_time}s ($((total_time / 60))m $((total_time % 60))s)"
        echo ""
        echo "Operations by duration (longest first):"
        
        # Sort timing data by duration (longest first)
        for operation in "${!TIMING_DATA[@]}"; do
            echo "${TIMING_DATA[$operation]} $operation"
        done | sort -nr | while read -r duration op; do
            if [ "$duration" -ge 60 ]; then
                echo "  $op: ${duration}s ($((duration / 60))m $((duration % 60))s)"
            else
                echo "  $op: ${duration}s"
            fi
        done
        
        echo ""
        echo "=== PARALLEL EXECUTION BENEFITS ==="
        echo "🚀 Operations executed in parallel groups instead of sequentially"
        echo "⚡ Estimated time savings: Significant reduction from sequential cargo builds"
        echo "📊 Individual operation times above show actual parallel execution duration"
        echo ""
        echo "Completed: $(date)"
    } >> "$LOG_FILE"
}

# Export functions for use in main install script
export -f run_parallel
export -f wait_for_parallel
export -f install_cargo_packages_parallel
export -f install_cargo_packages_background
export -f install_cargo_packages_background_remaining
export -f install_external_tools_parallel
export -f setup_git_tools_parallel
export -f generate_timing_summary
export -f log_with_timing
export -f start_operation
