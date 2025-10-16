#!/usr/bin/env bash
# Helper script to check Neovim setup status

PID_FILE=~/.dotfiles_neovim_setup.pid
LOG_FILE=~/.dotfiles_neovim_setup.log

if [ ! -f "$PID_FILE" ]; then
    echo "❌ No Neovim setup PID file found"
    echo "Either setup is complete or was never started"
    
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "📄 Last few lines of setup log:"
        tail -n 5 "$LOG_FILE"
    fi
    
    exit 1
fi

NEOVIM_PID=$(cat "$PID_FILE")

if ps -p "$NEOVIM_PID" > /dev/null 2>&1; then
    echo "🔌 Neovim setup is still running (PID: $NEOVIM_PID)"
    echo ""
    echo "📄 Recent progress:"
    if [ -f "$LOG_FILE" ]; then
        tail -n 10 "$LOG_FILE"
    fi
    echo ""
    echo "Commands:"
    echo "  Watch progress:  tail -f $LOG_FILE"
    echo "  Wait for finish: wait $NEOVIM_PID"
    echo "  Check again:     $0"
else
    echo "✅ Neovim setup has completed (PID $NEOVIM_PID no longer running)"
    
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "📄 Final status:"
        tail -n 5 "$LOG_FILE"
        
        if grep -q "🎉 All Neovim setup completed successfully" "$LOG_FILE"; then
            echo ""
            echo "🎉 Setup completed successfully!"
            
            # Check if neovim is available
            echo ""
            echo "🔍 Checking Neovim availability:"
            if command -v nvim &> /dev/null; then
                echo "  ✅ nvim is available"
                echo "  📦 Plugins and language servers should be ready"
            else
                echo "  ❌ nvim not found in PATH"
            fi
        else
            echo ""
            echo "❌ Setup may have failed - check log for details"
        fi
    fi
    
    # Clean up PID file
    rm -f "$PID_FILE"
fi