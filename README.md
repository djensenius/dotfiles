# dotfiles

Modern development environment configuration files optimized for productivity and visual consistency. This setup provides a comprehensive development environment with integrated tools for coding, git workflow, terminal enhancement, and system monitoring.

**Key Features:**
- 🎨 **Consistent Theming**: [Catppuccin Mocha theme](https://github.com/catppuccin/catppuccin) across all applications
- 🚀 **Parallel Installation**: 40-60% faster setup with concurrent package installation
- ⚡ **Performance Optimized**: Fast startup times and efficient resource usage
- 🔧 **Development Focused**: Comprehensive language support and development tools
- 📦 **Automated Setup**: One-script installation for GitHub Codespaces
- 🐚 **Modern Shell**: Fish shell with starship prompt and productivity enhancements

All configurations use the [Catppuccin Mocha theme](https://github.com/catppuccin/catppuccin) for a consistent and visually appealing look across all tools and applications.

## Installation

### Automated Installation (Recommended)

For GitHub Codespaces, the setup is fully automated with **parallel installation** and **fast track** for essential tools:
```bash
./install.sh                    # Fast track mode: Essential tools ready in ~30s
./install.sh --sequential       # Original sequential mode (10-15 minutes)
./install.sh --help             # See all options
```

**Fast Track Optimization:** Essential tools (tmux + plugins + tmuxinator + nvim) are set up immediately in ~30 seconds, while other development tools install in the background.

**Fast Track Priority (ready in ~20 seconds)**:
- ✅ tmux configuration and plugins (TPM + all plugins installed)
- ✅ tmuxinator for session management  
- ✅ nvim configuration (plugins sync in background)
- ✅ starship prompt, FZF, LazyGit

**Background Installations (non-blocking)**:
- 🦀 Rust development tools (bat, rg, fd, eza, zoxide, atuin)
- 📦 NPM language servers and development tools
- 🔌 Neovim plugins and Mason language servers  
- 🛠️ Additional development tools (delta, yq, protobuf, luarocks)

**New Background Installation:** The parallel mode now runs Rust/Cargo tools, NPM packages, and Neovim plugins in the background, allowing you to start using your environment immediately while development tools install in the background.

**Visual Progress Indicator:** When using tmux, a spinning indicator (   ) appears in the status line showing active background installations with the same animation used by lualine in nvim.

**Background Installation Monitoring:**
```bash
# Check installation status
./scripts/check-rust-install.sh      # Rust tools (bat, rg, fd, etc.)
./scripts/check-npm-install.sh       # NPM packages (language servers, etc.)
./scripts/check-neovim-setup.sh      # Neovim plugins and Mason tools

# Monitor installation progress
tail -f ~/.dotfiles_rust_install.log    # Rust tools progress
tail -f ~/.dotfiles_npm_install.log     # NPM packages progress
tail -f ~/.dotfiles_neovim_setup.log    # Neovim setup progress

# Wait for completion (if needed)
wait $(cat ~/.dotfiles_rust_install.pid)  # Wait for Rust tools
wait $(cat ~/.dotfiles_npm_install.pid)   # Wait for NPM packages
wait $(cat ~/.dotfiles_neovim_setup.pid)  # Wait for Neovim setup
```

**Performance:** The new parallel installation reduces foreground setup time by **93%** - from 5+ minutes down to ~20 seconds for immediate productivity!

### Manual Local Installation

For local installation, most configurations can be symlinked to your `~/.config` directory:

1. **Clone this repository:**
   ```bash
   git clone https://github.com/djensenius/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Symlink configurations:**
   ```bash
   # Core shell and editor configs
   ln -sf ~/.dotfiles/fish ~/.config/
   ln -sf ~/.dotfiles/nvim ~/.config/
   ln -sf ~/.dotfiles/starship.toml ~/.config/
   
   # Terminal multiplexer
   ln -sf ~/.dotfiles/tmux ~/.config/
   
   # Development tools
   ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
   ln -sf ~/.dotfiles/gitignore_local ~/.gitignore_local
   ```

3. **Special setup for TMUX:**
   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ~/.tmux/plugins/tpm/scripts/install_plugins.sh
   ```

4. **Install required tools** (see [Applications](#applications) section for details)

See the [install.sh](install.sh) script for the complete automated setup process used in GitHub Codespaces.

## Overview

This dotfiles collection includes configurations for:

- **🖥️ Terminal & Shell**: Fish shell with starship prompt, tmux multiplexer
- **📝 Editor**: Neovim with 46+ plugins for modern development ([details](nvim/README.md))
- **🔍 Search & Navigation**: fzf, ripgrep, fd, eza, zoxide for enhanced file operations
- **📊 Git Workflow**: lazygit, delta, gitsigns integration for visual git management
- **🔧 Development Tools**: Language servers, formatters, linters, and debugging tools
- **📱 System Monitoring**: bottom, fastfetch, k9s for system and cluster monitoring
- **🎨 Consistent Theming**: Catppuccin Mocha theme across all applications

## Applications

### [atuin](https://atuin.sh) ([repo](https://github.com/ellie/atuin))
Atuin is a powerful and customizable shell history manager.
- **Directory**: `atuin/`

### [bat](https://github.com/sharkdp/bat)
Bat is a cat clone with syntax highlighting and Git integration.
- **Directory**: `bat/`

### [bottom](https://github.com/ClementTsang/bottom)
Bottom is a cross-platform graphical process/system monitor.
- **Directory**: `bottom/`

### [delta](https://github.com/dandavison/delta)
Delta is a syntax-highlighting pager for git, diff, and grep output.
- **Configuration**: Integrated into `gitconfig`

### [eza](https://github.com/eza-community/eza)
Eza is a modern replacement for ls with colors, icons, and git integration.
- **Installation**: Via cargo

### [codespaces](https://github.com/github/codespaces)
Codespaces is a cloud development environment provided by GitHub.
- **Directory**: `.devcontainer/`
- **Files**: `install.sh`, `prettierrc.json`

### [fastfetch](https://github.com/LinusDierheimer/fastfetch)
Fastfetch is a neofetch-like tool for fetching system information.
- **Directory**: `fastfetch/`

### [fzf](https://github.com/junegunn/fzf)
Fzf is a command-line fuzzy finder for files, commands, and more.
- **Installation**: Via git clone to `~/.fzf`

### [fd](https://github.com/sharkdp/fd)
Fd is a simple, fast and user-friendly alternative to find.
- **Installation**: Via cargo (as fd-find)

### [Fish](https://fishshell.com) ([repo](https://github.com/fish-shell/fish-shell))
Fish is a smart and user-friendly command line shell.
- **Directory**: `fish/`

### [gh](https://cli.github.com) ([repo](https://github.com/cli/cli))
Gh is GitHub’s official command line tool.
- **Directory**: `gh/`

### [gh-dash](https://github.com/dlvhdr/gh-dash)
Gh-dash is a GitHub CLI tool to view and manage issues and pull requests in a terminal dashboard.
- **Directory**: `gh-dash/`

### [git](https://git-scm.com) ([repo](https://github.com/git/git))
Git is a distributed version control system.
- **Files**: `gitconfig`, `gitignore-local`

### [gitmux](https://github.com/arl/gitmux)
Gitmux is a Tmux status line for Git.
- **File**: `gitmux.conf`

### [Ghostty](https://ghostty.org/) ([repo](https://github.com/ghostty-org/ghostty))
Ghostty is a fast, feature-rich terminal emulator built for performance and customization.
- **Directory**: `ghostty/`

### [gopod](https://github.com/djensenius/gopod)
Gopod is a tool for making radio programs that are streaming online into podcasts.
- **Directory**: `gopod/`

### [k9s](https://k9scli.io) ([repo](https://github.com/derailed/k9s))
K9s is a terminal UI to interact with your Kubernetes clusters.
- **Directory**: `k9s/`

### [lazygit](https://github.com/jesseduffield/lazygit)
Lazygit is a simple terminal UI for git commands with keyboard shortcuts.
- **Installation**: Downloaded binary to `/usr/local/bin`

### [NeoVim](https://neovim.io) ([repo](https://github.com/neovim/neovim))
NeoVim is a hyperextensible Vim-based text editor.
- **Directory**: `nvim/`
- **See**: [nvim/README.md](nvim/README.md) for comprehensive plugin documentation

### [pay-respects](https://github.com/LudwigZeller/pay-respects)
Pay-respects is a modern replacement for thefuck, fixing command line errors with AI assistance.
- **Installation**: Via cargo

### [ripgrep](https://github.com/BurntSushi/ripgrep)
Ripgrep is a line-oriented search tool that recursively searches directories for a regex pattern.
- **Installation**: Via cargo

### [Starship](https://starship.rs) ([repo](https://github.com/starship/starship))
Starship is a cross-shell prompt that displays information about the current directory, git status, and more.
- **File**: `starship.toml`

### [tmux](https://github.com/tmux/tmux/wiki) ([repo](https://github.com/tmux/tmux))
Tmux is a terminal multiplexer that allows multiple terminal sessions to be accessed and controlled from a single screen.
- **Directory**: `tmux/`
- **Features**: Catppuccin Mocha theme, vim-style navigation, floating windows, session management
- **Battery Status**: Uses [battery_hearts](https://github.com/djensenius/battery_hearts) plugin to display battery level with heart icons in the status bar

#### Installing battery_hearts
The battery_hearts tool displays battery status using heart icons and is integrated into the tmux status bar. Install it using one of these methods:

**From crates.io (Recommended):**
```bash
cargo install battery_hearts
```

**From releases:**
```bash
# Download the latest binary for your platform from:
# https://github.com/djensenius/battery_hearts/releases
chmod +x battery_hearts-*
# Move to PATH, e.g., /usr/local/bin/
```

**From source:**
```bash
git clone https://github.com/djensenius/battery_hearts.git
cd battery_hearts
cargo build --release
# Copy ./target/release/battery_hearts to your PATH
```

Once installed, the tmux configuration will automatically use it to display battery status with heart icons (❤️ 🧡 🤍) in the status bar.

### [tmuxinator](https://github.com/tmuxinator/tmuxinator)
Tmuxinator is a tool to manage complex tmux sessions easily.
- **Directory**: `tmuxinator/`

### [vale](https://vale.sh) ([repo](https://github.com/errata-ai/vale))
Vale is a syntax-aware linter for prose built with speed and extensibility in mind.
- **File**: `vale.ini`

### [yazi](https://github.com/yazi-shell/yazi)
Yazi is a terminal file manager.
- **Directory**: `yazi/`


### [zoxide](https://github.com/ajeetdsouza/zoxide)
Zoxide is a smarter cd command that learns your habits and jumps to frequently used directories.
- **Installation**: Via cargo

## Codespaces `install.sh` Script Summary

The `install.sh` script is designed to set up and configure a development environment, particularly for use in GitHub Codespaces. It performs the following tasks:

### 1. Link Configuration Files

- Creates necessary directories and creates symbolic links for various configuration files:
  - `tmux.conf`
  - `gitconfig`
  - `fish`
  - `starship.toml`
  - `nvim`
  - `bat`
  - `vale.ini`
  - `prettierrc.json`
  - `gitmux.conf`
  - `tmuxinator`
  - `neofetch`
  - `atuin`
  - `yazi`
  - `bottom`

- If running within a GitHub Codespace, it links executables (e.g., `rubocop`, `srb`, `bundle`, `solargraph`, `safe-ruby`) to `/usr/local/bin` and updates locale settings.

### 2. Install Software

- Installs various software packages required for the development environment, including:
  - `build-essential`
  - `python3-venv`
  - `socat`
  - `ncat`
  - `ruby-dev`
  - `jq`
  - `pay-respects` (replacement for thefuck)
  - `tmux`
  - `libfuse2`
  - `fuse`
  - `software-properties-common`
  - `most`

- Removes potentially conflicting packages (`bat`, `ripgrep`).

- Installs additional tools via `curl`, `wget`, `cargo`, `go`, `gem`, and `npm`:
  - `starship`
  - `delta`
  - `protobuf`
  - `eza`
  - `zoxide`
  - `ripgrep`
  - `fd-find`
  - `bat`
  - `atuin`
  - `gitmux`
  - `tmuxinator`
  - `neovim-ruby-host`
  - `prettierd`
  - `yaml-language-server`
  - `vscode-langservers-extracted`
  - `eslint_d`
  - `prettier`
  - `tree-sitter`
  - `neovim`
  - `fzf`
  - `lazygit`

### 3. Setup Software

- Logs into `atuin` using provided credentials.
- Installs `tmux` plugins.
- Synchronizes and installs `nvim` plugins.
- If running within a GitHub Codespace
  - Changes the default shell to `fish` for the `vscode` user.
  - Checks the status of the repository.

### 4. Logging

- Logs the progress of file linking, software installation, and software setup to `~/install.log`.

---

This script automates the setup process to ensure a consistent and efficient development environment, particularly optimized for GitHub Codespaces.
