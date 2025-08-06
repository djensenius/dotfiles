# Neovim Configuration

A comprehensive Neovim configuration built with [lazy.nvim](https://github.com/folke/lazy.nvim) plugin manager, designed for efficient development across multiple programming languages. This configuration emphasizes productivity, visual appeal, and seamless integration with modern development workflows.

## Features

- **Modern Plugin Management**: Uses [lazy.nvim](https://github.com/folke/lazy.nvim) for fast and efficient plugin loading
- **Consistent Theme**: [Catppuccin Mocha](https://github.com/catppuccin/catppuccin) theme across all components
- **LSP Integration**: Full Language Server Protocol support with autocompletion, diagnostics, and formatting
- **Git Integration**: Comprehensive git workflow with visual diff, blame, and staging capabilities
- **File Management**: Multiple file browsers and fuzzy finders for efficient navigation
- **Development Tools**: Integrated testing, debugging, and code quality tools

## Installation

The configuration is automatically set up through the main [install.sh](../install.sh) script. For manual installation:

1. Backup your existing Neovim configuration:
   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   ```

2. Clone and link this configuration:
   ```bash
   ln -sf /path/to/this/nvim ~/.config/
   ```

3. Start Neovim and let lazy.nvim install plugins:
   ```bash
   nvim
   ```

## Structure

```
nvim/
├── init.lua              # Main configuration entry point
├── lua/
│   ├── basic.lua         # Basic Neovim settings and options
│   ├── keys.lua          # Global key mappings
│   ├── core/
│   │   └── utils.lua     # Utility functions
│   └── plugins/          # Plugin configurations (43 plugins)
└── README.md             # This file
```

## Key Mappings

The leader key is set to `,` (comma). Here are the main key mappings:

### File Operations
- `<leader>w` - Save file
- `<leader>q` - Quit
- `<leader>cf` - Copy full file path
- `<leader>cr` - Copy relative file path

### Navigation
- `<S-h>` / `<S-l>` - Previous/Next buffer
- `<S-j>` / `<S-k>` - Next/Previous tab
- `<C-h/j/k/l>` - Navigate splits (handled by vim-tmux-navigator)

### Finding & Search
- `<leader>ff` - Find files (Telescope)
- `<leader>fg` - Live grep search (Telescope)
- `<leader>fb` - Browse buffers (Telescope)
- `<leader>fh` - Help tags (Telescope)
- `<leader>fd` - LSP definitions (Telescope)
- `<leader>fr` - LSP references (Telescope)

### Git Operations
- `<leader>gL` - LazyGit interface
- `<leader>gc` - Git commit (Neogit)
- `<leader>gb` - Toggle line blame
- `<leader>gs` - Stage hunk
- `<leader>gr` - Reset hunk
- `<leader>gp` - Preview hunk
- `<leader>gj/gk` - Next/Previous hunk

### File Management
- `<leader>tg` - Toggle Neo-tree
- `<leader>tb` - Show buffers in Neo-tree
- `<leader>tF` - Reveal current file in Neo-tree

### Code & LSP
- `<leader>fmt` - Format buffer (Conform)
- `<leader>tt*` - Trouble diagnostics (various modes)

### Copilot Integration
- `<leader>cp` - Copilot panel
- `<leader>cc*` - CopilotChat commands (explain, review, fix, etc.)

## Plugins Overview

### Core & UI

#### [lazy.nvim](https://github.com/folke/lazy.nvim)
Modern plugin manager with lazy loading and automatic installation.

#### [catppuccin/nvim](https://github.com/catppuccin/catppuccin)
Beautiful pastel theme providing consistent visual experience across all components.

#### [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
Fast and configurable statusline with git status, LSP info, and diagnostic indicators.

#### [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
Enhanced buffer/tab line with git indicators and file type icons.

#### [which-key.nvim](https://github.com/folke/which-key.nvim)
Interactive key mapping helper that displays available keybindings.

#### [noice.nvim](https://github.com/folke/noice.nvim)
Enhanced UI for messages, cmdline, and popupmenu.

#### [nvim-notify](https://github.com/rcarriga/nvim-notify)
Fancy notification manager with animations and history.

#### [alpha-nvim](https://github.com/goolord/alpha-nvim)
Customizable start screen/dashboard.

### File Management & Navigation

#### [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)
Modern file explorer with git status, document symbols, and buffer management.

#### [oil.nvim](https://github.com/stevearc/oil.nvim)
Edit your filesystem like a buffer - intuitive file operations.

#### [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
Highly extendable fuzzy finder for files, buffers, LSP symbols, and more.

#### [fzf-lua](https://github.com/ibhagwan/fzf-lua)
Fast fuzzy finder integration with native fzf performance.

### Language Support & LSP

#### [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
Quickstart configs for Neovim's built-in Language Server Protocol.

#### [mason.nvim](https://github.com/williamboman/mason.nvim)
Portable package manager for LSP servers, DAP servers, linters, and formatters.

#### [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim)
Bridge between mason.nvim and nvim-lspconfig.

#### [blink.cmp](https://github.com/saghen/blink.cmp)
Modern completion plugin with LSP support and snippet integration.

#### [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
Advanced syntax highlighting and code understanding for 65+ languages.

### Code Quality & Formatting

#### [conform.nvim](https://github.com/stevearc/conform.nvim)
Lightweight formatting plugin supporting multiple formatters per filetype.

#### [nvim-lint](https://github.com/mfussenegger/nvim-lint)
Asynchronous linter integration for code quality checks.

#### [trouble.nvim](https://github.com/folke/trouble.nvim)
Pretty diagnostics, references, telescope results, quickfix and location lists.

### Git Integration

#### [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)
Git decorations and functionality directly in the editor.

#### [neogit](https://github.com/NeogitOrg/neogit)
Magit-like git interface for Neovim.

#### [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim)
Integration with the lazygit terminal UI.

#### [gitgraph.nvim](https://github.com/isakbm/gitgraph.nvim)
Git graph visualization within Neovim.

### AI & Productivity

#### [copilot.vim](https://github.com/github/copilot.vim)
GitHub Copilot integration for AI-powered code suggestions.

#### [CopilotChat.nvim](https://github.com/CopilotC-Nvim/CopilotChat.nvim)
Interactive chat interface with GitHub Copilot for code explanation and generation.

### Testing & Debugging

#### [neotest](https://github.com/nvim-neotest/neotest)
Extensible testing framework with support for multiple test runners.

#### [nvim-dap](https://github.com/mfussenegger/nvim-dap)
Debug Adapter Protocol client for debugging applications.

#### [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)
UI for nvim-dap providing a debugger interface.

### Language-Specific

#### [go.nvim](https://github.com/ray-x/go.nvim)
Comprehensive Go development plugin with advanced features.

#### [vim-test](https://github.com/vim-test/vim-test)
Test runner for various programming languages.

### Editing Enhancements

#### [nvim-autopairs](https://github.com/windwp/nvim-autopairs)
Automatic bracket, quote, and tag pairing.

#### [mini.surround](https://github.com/echasnovski/mini.surround)
Surround text objects with brackets, quotes, and more.

#### [nvim-spectre](https://github.com/nvim-pack/nvim-spectre)
Search and replace across multiple files.

#### [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
Seamless navigation between Neovim and tmux panes.

### Utilities

#### [aerial.nvim](https://github.com/stevearc/aerial.nvim)
Code outline window showing document symbols.

#### [ufo](https://github.com/kevinhwang91/nvim-ufo)
Enhanced folding with virtual text and preview.

#### [oscyank.nvim](https://github.com/ojroques/vim-oscyank)
Copy text to system clipboard over SSH using OSC52.

#### [nvim-colorizer.lua](https://github.com/norcalli/nvim-colorizer.lua)
High-performance color highlighter for CSS colors and hex codes.

## Configuration Philosophy

This configuration follows several key principles:

1. **Lazy Loading**: Plugins are loaded only when needed to maintain fast startup times
2. **Consistent Theming**: Catppuccin Mocha theme is integrated across all components
3. **Minimal Conflicts**: Key mappings are designed to avoid conflicts and provide logical groupings
4. **Development Focus**: Optimized for modern software development workflows
5. **Extensibility**: Modular structure allows easy addition or removal of plugins

## Language Support

The configuration provides comprehensive support for:

- **Web Development**: JavaScript, TypeScript, HTML, CSS, React, Vue, Svelte
- **Systems Programming**: Go, Rust, C/C++, Zig
- **Scripting**: Python, Ruby, Bash, Fish, Lua
- **Markup**: Markdown, LaTeX, Typst
- **Data**: JSON, YAML, TOML, CSV
- **Version Control**: Git configuration files
- **DevOps**: Dockerfile, Kubernetes, Terraform

## Customization

To customize this configuration:

1. **Adding Plugins**: Create new files in `lua/plugins/` following the existing pattern
2. **Modifying Settings**: Edit `lua/basic.lua` for core Neovim options
3. **Key Mappings**: Add custom mappings to `lua/keys.lua` or individual plugin files
4. **Theme Changes**: Modify `lua/plugins/catppuccin.lua` for theme customization

## Performance

This configuration is optimized for performance:

- Startup time: ~50-100ms with lazy loading
- Memory usage: Efficient with on-demand plugin loading
- Large files: Optimized treesitter and LSP settings for handling large codebases

## Troubleshooting

Common issues and solutions:

1. **Slow startup**: Check `:Lazy profile` for plugin loading times
2. **LSP not working**: Verify language servers are installed via `:Mason`
3. **Key mappings conflict**: Use `:WhichKey` to see all available mappings
4. **Plugin errors**: Check `:Lazy` for plugin status and error messages

For more detailed troubleshooting, check the individual plugin documentation linked above.