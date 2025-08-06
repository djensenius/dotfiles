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

## Complex Setup Breakdowns

The following sections provide detailed explanations of the more sophisticated configurations in this setup:

### LSP Configuration (`nvim-lspconfig.lua`)

This is one of the most complex parts of the configuration, providing Language Server Protocol support for multiple programming languages.

#### Architecture
- **Multiple Language Servers**: Configured for TypeScript/JavaScript, Go, Lua, Ruby (Sorbet), YAML, JSON, ESLint, and Vale
- **Unified `on_attach` Function**: Provides consistent keybindings and behavior across all language servers
- **Custom Capabilities**: Integration with `blink.cmp` for completion and special YAML folding support

#### Key Features
- **Go LSP (`gopls`) Advanced Configuration**:
  - `gofumpt` formatting enabled for stricter formatting
  - `staticcheck` for additional static analysis
  - Code lenses for tests, dependency management, and upgrades
  - Custom build flags for integration tests (`-tags=integration`)
  - Directory filtering to exclude vendor folders

- **Diagnostic Customization**:
  - Custom icons for different severity levels (error 󰅚, warning 󰀪, info 󰋽, hint 󰌶)
  - Virtual text with source information
  - Underlines for warnings and errors only
  - Virtual lines for current line diagnostics

#### Keybindings (Leader + Space prefix)
- `<leader><space>c` - Go to declaration
- `<leader><space>D` - Go to definition (via Telescope)
- `<leader><space>h` - Show hover information
- `<leader><space>R` - Rename symbol
- `<leader><space>r` - Show references (via Telescope)
- `<leader><space>d` - Show diagnostics
- `<leader><space>i` - Show code actions

### Mason + DAP Configuration (`mason.lua`)

This setup provides a comprehensive debugging environment with automatic tool installation.

#### Tool Management
- **Automatic Installation**: 20+ LSP servers, formatters, and linters
- **Language Coverage**: Go, TypeScript/JavaScript, Python, Ruby, Lua, JSON, YAML
- **Debounced Updates**: Tools check for updates every 96 hours to avoid excessive network calls

#### Debug Adapter Protocol (DAP)
- **Multi-Language Support**: 
  - Go debugging with Delve
  - Ruby debugging support
  - Generic DAP configuration for other languages
- **UI Integration**: Automatic DAP UI opening/closing based on debug session state
- **Event Listeners**: Responds to debug session lifecycle events

#### Debug Keybindings
- **Function Keys**: `F5` (continue), `F10` (step over), `F11` (step into), `F12` (step out)
- **Leader Combinations**: 
  - `<leader><space>5` - Continue execution
  - `<leader><space>b` - Toggle breakpoint
  - `<leader><space>B` - Set conditional breakpoint
  - `<leader><space>pr` - Open debug REPL
  - `<leader><space>ph` - Hover widget for variable inspection

### Completion System (`blink-cmp.lua`)

Modern completion engine replacing the traditional `nvim-cmp` setup.

#### Features
- **Multiple Sources**: LSP, file paths, snippets, and buffer content
- **Smart Documentation**: Auto-showing with 250ms delay and treesitter highlighting
- **Signature Help**: Real-time function signature display
- **Visual Polish**: Rounded borders and nerd font icons

#### Integration
- **LSP Compatibility**: Full integration with all configured language servers
- **Snippet Support**: Uses `friendly-snippets` for extensive snippet library
- **Performance**: Lazy loading handled internally for optimal startup time

### Treesitter Configuration (`nvim-treesitter.lua`)

Provides advanced syntax highlighting and code understanding for 40+ languages.

#### Language Support
- **Comprehensive Coverage**: From web technologies (HTML, CSS, JavaScript, TypeScript) to systems languages (Go, Rust, C/C++)
- **Configuration Languages**: Docker, YAML, TOML, Git configs
- **Documentation**: Markdown, LaTeX, Typst
- **Specialized**: Supercollider, Norg, SSH configs

#### Advanced Features
- **Incremental Selection**: `gnn` to expand selection, `gnd` to shrink
- **Text Objects**: Enhanced with `nvim-treesitter-textobjects`
- **Smart Indentation**: Enabled for most languages (disabled for Python due to conflicts)

### Formatting System (`conform.nvim`)

Sophisticated formatter integration with language-specific configurations.

#### Multi-Formatter Support
- **JavaScript/TypeScript**: ESLint + Prettier with fallback chain
- **Go**: goimports followed by gofmt for import organization and formatting
- **Python**: isort for imports + black for code formatting
- **Ruby**: RuboCop for style and formatting

#### Smart Behavior
- **Conditional Format-on-Save**: Currently enabled only for Lua files
- **LSP Fallback**: Uses LSP formatting when dedicated formatters aren't available
- **Performance**: 500ms timeout to prevent blocking

### Testing Framework (`neotest.lua`)

Integrated testing environment with visual feedback.

#### Jest Integration
- **Automatic Discovery**: Finds and runs Jest tests in JavaScript/TypeScript projects
- **Configuration Aware**: Uses `jest.config.js` when present
- **Visual Indicators**: Shows test status with signs in the gutter

#### Test Commands
- `:NeotestSummary` - Toggle test results summary
- `:NeotestFile` - Run all tests in current file
- `:NeotestNearest` - Run test under cursor
- `:NeotestDebug` - Debug test with DAP integration

#### Status Display
- **Non-Intrusive**: Virtual text disabled to avoid clutter
- **Sign Column**: Uses gutter signs for test status
- **Integration**: Works with trouble.nvim for diagnostic display

### Git Integration Stack

Multiple complementary git tools providing complete workflow coverage:

#### Gitsigns (`gitsigns.nvim`)
- **Real-time Diff**: Shows changes in sign column
- **Hunk Operations**: Stage, reset, and preview individual changes
- **Blame Integration**: Inline blame information

#### Neogit (`neogit.nvim`)
- **Magit-like Interface**: Comprehensive git operations in Neovim
- **Staging Area**: Visual staging and unstaging of changes
- **Commit Interface**: Built-in commit message editing

#### LazyGit Integration (`lazygit.nvim`)
- **Terminal UI**: Full-featured git interface
- **External Tool**: Maintains separate terminal-based workflow
- **Quick Access**: `<leader>gL` for instant access

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