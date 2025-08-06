# dotfiles

My config files for various applications to enhance development efficiency and experience. All configurations use the [Catppuccin Mocha theme](https://github.com/catppuccin/catppuccin) for a consistent and visually appealing look across all tools and applications.

## Local installation

TMUX is a little special and needs this:
```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/scripts/install_plugins.sh
```

Otherwise you *mostly* just symlink to your `~/.config` directory. Take a look at [install.sh](install.sh)
which is used for setting up codespaces if you run into any problems.

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
Ghostty is a tool for managing dotfiles across multiple machines.
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

### [pay-respects](https://github.com/LudwigZeller/pay-respects)
Pay-respects is a modern replacement for thefuck, fixing command line errors with AI assistance.
- **Installation**: Via cargo

### [Starship](https://starship.rs) ([repo](https://github.com/starship/starship))
Starship is a cross-shell prompt that displays information about the current directory, git status, and more.
- **File**: `starship.toml`

### [tmux](https://github.com/tmux/tmux/wiki) ([repo](https://github.com/tmux/tmux))
Tmux is a terminal multiplexer that allows multiple terminal sessions to be accessed and controlled from a single screen.
- **Directory**: `tmux/`

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
