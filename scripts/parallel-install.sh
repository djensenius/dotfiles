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
        
        if wait $pid; then
            # Extract timing from log file
            local duration=$(grep "completed in" "$log_file" | grep -o '[0-9]\+s' | head -1 | sed 's/s//')
            if [[ -n "$duration" ]]; then
                TIMING_DATA["$operation"]=$duration
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $operation completed (${duration}s)" >> $LOG_FILE
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $operation completed" >> $LOG_FILE
            fi
            
            # Append operation log to main log
            echo "" >> $LOG_FILE
            echo "--- $operation output ---" >> $LOG_FILE
            cat "$log_file" >> $LOG_FILE
            echo "--- end $operation output ---" >> $LOG_FILE
            echo "" >> $LOG_FILE
        else
            failed_operations+=("$operation")
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $operation FAILED" >> $LOG_FILE
            
            # Still append log for debugging
            echo "" >> $LOG_FILE
            echo "--- $operation FAILED output ---" >> $LOG_FILE
            cat "$log_file" >> $LOG_FILE
            echo "--- end $operation FAILED output ---" >> $LOG_FILE
            echo "" >> $LOG_FILE
        fi
        
        # Clean up log file
        rm -f "$log_file"
        unset PARALLEL_PIDS["$operation"]
        unset PARALLEL_LOGS["$operation"]
    done
    
    if [[ ${#failed_operations[@]} -gt 0 ]]; then
        echo "❌ The following operations failed: ${failed_operations[*]}" >> $LOG_FILE
        return 1
    fi
    
    return 0
}

# Enhanced cargo installation with parallel execution
install_cargo_packages_parallel() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 Starting parallel cargo installations..." >> $LOG_FILE
    
    # Start all cargo installations in parallel
    run_parallel "cargo_eza" "cargo install eza"
    run_parallel "cargo_zoxide" "cargo install --locked zoxide"
    run_parallel "cargo_ripgrep" "cargo install ripgrep"
    run_parallel "cargo_fd_find" "cargo install fd-find"
    run_parallel "cargo_bat" "cargo install --locked bat"
    run_parallel "cargo_atuin" "cargo install --locked atuin"
    run_parallel "cargo_tree_sitter" "cargo install --locked tree-sitter-cli"
    
    # Pay-respects tools (group them since they're related)
    run_parallel "cargo_pay_respects" "
        cargo install --locked pay-respects &&
        cargo install --locked pay-respects-module-runtime-rules &&
        cargo install --locked pay-respects-module-request-ai
    "
    
    # Wait for all cargo installations to complete
    local cargo_operations=(
        "cargo_eza" "cargo_zoxide" "cargo_ripgrep" "cargo_fd_find" 
        "cargo_bat" "cargo_atuin" "cargo_tree_sitter" "cargo_pay_respects"
    )
    
    if wait_for_parallel "${cargo_operations[@]}"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ All cargo installations completed successfully" >> $LOG_FILE
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Some cargo installations failed" >> $LOG_FILE
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
    
    # Wait for all downloads to complete
    local download_operations=(
        "starship_install" "git_delta_install" "delta_themes_download" 
        "yq_install" "protobuf_install" "fzf_install" "lazygit_install"
    )
    
    if wait_for_parallel "${download_operations[@]}"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ All external tool downloads completed successfully" >> $LOG_FILE
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
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    TIMING_DATA["$operation"]=$duration
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $operation (${duration}s)" >> $LOG_FILE
}

# Helper function to start timing an operation (from original script)
start_operation() {
    local operation="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔄 Starting: $operation" >> $LOG_FILE
    echo $(date +%s)
}

# Generate timing summary with parallel operation insights
generate_timing_summary() {
    local total_time=$(($(date +%s) - INSTALL_START_TIME))
    
    echo "" >> $LOG_FILE
    echo "=== PARALLEL INSTALLATION TIMING SUMMARY ===" >> $LOG_FILE
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
    echo "=== PARALLEL EXECUTION BENEFITS ===" >> $LOG_FILE
    echo "🚀 Operations executed in parallel groups instead of sequentially" >> $LOG_FILE
    echo "⚡ Estimated time savings: Significant reduction from sequential cargo builds" >> $LOG_FILE
    echo "📊 Individual operation times above show actual parallel execution duration" >> $LOG_FILE
    
    echo "" >> $LOG_FILE
    echo "Completed: $(date)" >> $LOG_FILE
}

# Export functions for use in main install script
export -f run_parallel
export -f wait_for_parallel
export -f install_cargo_packages_parallel
export -f install_external_tools_parallel
export -f setup_git_tools_parallel
export -f generate_timing_summary
export -f log_with_timing
export -f start_operation