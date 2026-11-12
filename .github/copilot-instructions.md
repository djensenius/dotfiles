# dotfiles Repository Development Guide

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Repository Overview

This is a dotfiles repository containing configuration files for various development tools (neovim, tmux, fish shell, etc.) using the Catppuccin Mocha theme for consistent styling. The repository supports both GitHub Codespaces (automated setup) and local installation (manual symlinking).

## Working Effectively

### Quick Setup Commands
For GitHub Codespaces (automated):
- `./install.sh` -- NEVER CANCEL: Full setup takes 10-15 minutes including package installation, configuration linking, and plugin setup.

For local development (manual):
- `mkdir -p ~/.config`  
- `ln -sf $(pwd)/fish ~/.config/`
- `ln -sf $(pwd)/nvim ~/.config/`
- `ln -sf $(pwd)/tmux ~/.config/`
- `ln -sf $(pwd)/starship.toml ~/.config/`
- `ln -sf $(pwd)/gitconfig ~/.gitconfig`
- `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm` -- takes 1-2 seconds
- `~/.tmux/plugins/tpm/scripts/install_plugins.sh` -- takes 2-3 seconds

### Validation Commands (Required Before Commits)
Run these linting commands to ensure CI passes:
- `yamllint .` -- takes 0.4 seconds. NEVER CANCEL.
- `pip install tomllint && for f in **/*.toml; do [ -f "$f" ] && tomllint "$f"; done` -- takes 0.1 seconds. NEVER CANCEL.
- `curl -L https://github.com/rhysd/actionlint/releases/latest/download/actionlint_1.7.7_linux_amd64.tar.gz | tar xzf - actionlint && ./actionlint` -- takes 0.6 seconds. NEVER CANCEL.

### Configuration Structure
- **fish/**: Fish shell configuration with modular setup in conf.d/
  - `config.fish`: Main interactive shell setup
  - `conf.d/*.fish`: Modular configuration files (environment, paths, aliases, etc.)
- **nvim/**: Neovim configuration using Lazy.nvim plugin manager
  - `init.lua`: Main entry point
  - `lua/plugins/`: Individual plugin configurations (40+ plugins)
- **tmux/**: Tmux configuration using TPM (tmux plugin manager)
  - `tmux.conf`: Main tmux configuration
- **Various tool configs**: starship.toml, gitconfig, atuin/, bat/, yazi/, etc.

## Validation Scenarios

### Testing Configuration Changes
Always test configuration changes by:
1. **Link Validation**: Ensure symlinks are created correctly
   - `ls -la ~/.config/` to verify symlinks point to repository files
2. **Tool Loading**: Test that tools can load configurations without errors
   - `tmux new-session -d -s test` then `tmux kill-session -t test` (test tmux config)
   - `fish -c "echo 'Fish config loaded successfully'"` (test fish config)
3. **Linting**: Run all validation commands listed above
4. **Plugin Installation**: For tmux changes, reinstall plugins to ensure compatibility

### Common Validation Workflows
- **After modifying YAML files**: Run `yamllint .`
- **After modifying TOML files**: Run tomllint on affected files
- **After modifying GitHub Actions**: Run actionlint
- **After modifying tmux config**: Test tmux can start with new config
- **After modifying fish config**: Test fish shell can source config files
- **After modifying nvim config**: Check lua syntax if possible

## Critical Setup Information

### Environment Requirements
- **GitHub Codespaces**: Uses `/workspaces/github` detection for special Codespaces-only setup
- **Local Development**: Requires manual installation of tools (fish, tmux, nvim, etc.)
- **Dependencies**: git, curl, wget are required for most setup operations

### Tool Installation Methods
- **Codespaces**: `install.sh` handles all package installation via apt, cargo, npm, gem
- **Local**: Manual installation of fish, tmux, neovim, starship, and other tools required
- **Plugin Managers Used**:
  - Neovim: Lazy.nvim (auto-installed on first run)
  - Tmux: TPM (must be manually cloned)
  - Fish: Built-in package management

### Timing Expectations
- **Full Codespaces setup**: 10-15 minutes (NEVER CANCEL)
- **Manual local setup**: 2-5 minutes
- **Validation linting**: Under 1 second total
- **Tmux plugin installation**: 2-3 seconds
- **Neovim plugin sync**: 1-2 minutes (NEVER CANCEL)

## Key File Locations

### Configuration Entry Points
- `install.sh`: Main setup script for Codespaces
- `README.md`: User documentation and application overview
- `fish/config.fish`: Fish shell interactive setup
- `nvim/init.lua`: Neovim entry point
- `tmux/tmux.conf`: Tmux configuration

### Linting Configuration
- `.yamllint`: YAML linting rules
- `.luacheckrc`: Lua linting configuration for neovim
- `.github/workflows/`: CI validation workflows

### Important Directories
- `fish/conf.d/`: Modular fish shell configuration
- `nvim/lua/plugins/`: Individual neovim plugin configurations
- `.github/workflows/`: GitHub Actions for linting validation

## Working with Different Environments

### GitHub Codespaces Detection
The repository detects Codespaces environment via:
- `/workspaces/github` directory existence
- Special setup for vscode user and locale settings
- Atuin login automation with environment variables

### Local vs Codespaces Differences
- **Codespaces**: Automated package installation and setup
- **Local**: Manual tool installation required
- **Shell**: Codespaces changes default shell to fish for vscode user
- **Paths**: Different cargo/atuin paths between environments

## Common Operations

### Adding New Configuration
1. Create configuration files in appropriate directory
2. Update `install.sh` link_files function if new symlinks needed
3. Test manual symlinking works: `ln -sf $(pwd)/newconfig ~/.config/`
4. Run validation commands
5. Update README.md if adding new application

### Modifying Existing Configurations
1. Edit configuration files directly
2. Test changes don't break tool loading
3. Run relevant validation commands
4. For plugin configs, ensure plugins can still be installed/loaded

### Troubleshooting Setup Issues
- **Broken symlinks**: Check `ls -la ~/.config/` and recreate with correct paths
- **Plugin failures**: Re-run plugin installation commands
- **Permission issues**: Ensure files are readable and directories exist
- **Path issues**: Check fish conf.d files for path configuration

Always validate changes by actually testing tool functionality, not just syntax checking.