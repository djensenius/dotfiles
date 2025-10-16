#!/usr/bin/env bash
# Helper script to check Rust installation status

PID_FILE=~/.dotfiles_rust_install.pid
LOG_FILE=~/.dotfiles_rust_install.log

if [ ! -f "$PID_FILE" ]; then
    echo "❌ No Rust installation PID file found"
    echo "Either installation is complete or was never started"
    
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "📄 Last few lines of installation log:"
        tail -n 5 "$LOG_FILE"
    fi
    
    exit 1
fi

RUST_PID=$(cat "$PID_FILE")

if ps -p "$RUST_PID" > /dev/null 2>&1; then
    echo "🦀 Rust installation is still running (PID: $RUST_PID)"
    echo ""
    echo "📄 Recent progress:"
    if [ -f "$LOG_FILE" ]; then
        tail -n 10 "$LOG_FILE"
    fi
    echo ""
    echo "Commands:"
    echo "  Watch progress:  tail -f $LOG_FILE"
    echo "  Wait for finish: wait $RUST_PID"
    echo "  Check again:     $0"
else
    echo "✅ Rust installation has completed (PID $RUST_PID no longer running)"
    
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "📄 Final status:"
        tail -n 5 "$LOG_FILE"
        
        if grep -q "🎉 All Rust tools installation completed successfully" "$LOG_FILE"; then
            echo ""
            echo "🎉 Installation completed successfully!"
            
            # Check if installed tools are available
            echo ""
            echo "🔍 Checking installed tools:"
            for tool in bat cargo fd rg eza zoxide atuin; do
                if command -v "$tool" &> /dev/null; then
                    echo "  ✅ $tool is available"
                else
                    echo "  ❌ $tool not found in PATH"
                fi
            done
        else
            echo ""
            echo "❌ Installation may have failed - check log for details"
        fi
    fi
    
    # Clean up PID file
    rm -f "$PID_FILE"
fi