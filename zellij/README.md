# Zellij Configuration

Modern terminal multiplexer configuration matching the aesthetic and functionality of the tmux setup.

## Features

- **🎨 Catppuccin Mocha Theme**: Consistent theming with rounded tabs
- **📍 Status Bar**: Top-positioned status bar using zjstatus plugin
- **💡 Keybinding Hints Bar**: Bottom compact-bar showing available keybindings for current mode
- **⌨️ Tmux-style Keybindings**: Familiar Ctrl+a prefix key
- **🔀 Vim Navigation**: Seamless pane navigation with vim-style keys
- **🎯 Nerd Font Icons**: Rich visual indicators for tabs and status
- **🪟 Tab Management**: Shows tab index and name with visual indicators

## File Structure

```
zellij/
├── config.kdl              # Main configuration file
├── themes/
│   └── catppuccin-mocha.kdl # Catppuccin Mocha color scheme
├── layouts/
│   ├── default.kdl         # Default layout with full status bar
│   └── compact.kdl         # Compact layout for more screen space
└── README.md               # This file
```

## Configuration Highlights

### Theme
- Uses Catppuccin Mocha color palette
- Rounded tabs with smooth transitions
- Background colors: Base (#1e1e2e), Surface2 (#585b70) for active tabs
- Mantle (#181825) for status bar background

### Keybindings

This configuration uses **Zellij's default keybindings** with an added **tmux mode** for tmux-compatible shortcuts.

#### Tmux Mode (Ctrl+a prefix)
- **Prefix**: `Ctrl+a` to enter tmux mode (matching tmux configuration)
- **Toggle UI**: `b` to toggle pane frames and keybinding hints bar (matching tmux Ctrl+b)
- **Navigation**: `h/j/k/l` for vim-style pane movement
- **Resize**: `Ctrl+h/j/k/l` for pane resizing
- **Split**: `|` or `\` for vertical, `-` or `_` for horizontal
- **Tabs**: `c` to create, `p`/`n` for previous/next, `1-9` for direct access
- **Close**: `q` or `x` to close pane
- **Scroll**: `[` to enter scroll mode
- **Search**: `/` to search in scrollback
- **Session**: `o` to open session manager
- **Fullscreen**: `z` to toggle fullscreen
- **Floating**: `w` to toggle floating pane

#### Default Zellij Keybindings
All standard Zellij keybindings remain available:
- **F1**: Toggle pane frames and keybinding hints bar (matching tmux F1 status toggle)
- **Ctrl+p**: Pane mode
- **Ctrl+t**: Tab mode
- **Ctrl+n**: Resize mode
- **Ctrl+s**: Scroll mode
- **Ctrl+o**: Session mode
- **Ctrl+h**: Move mode
- **Ctrl+g**: Lock mode (pass keys to terminal)
- **Ctrl+q**: Quit

See [Zellij Keybindings Documentation](https://zellij.dev/documentation/keybindings.html) for complete default keybinding reference.

### Status Bar (zjstatus)
The default layout uses the zjstatus plugin to provide a rich status bar at the top:

- **Left**: Mode indicator + Tabs with rounded corners
- **Right**: Session name + Date/Time
- **Tab Format**: 
  - Normal tabs: Grey background with subtle separator
  - Active tab: Highlighted with Surface2 color
  - Icons for fullscreen (󰊓) and sync () states

### Keybinding Hints Bar (compact-bar)
A keybinding hints bar is displayed at the bottom showing available commands for the current mode:

- **Toggle visibility**: Press `F1` or `Ctrl+a b` to hide/show the hints bar
- **What it shows**: Available keybindings for the current mode (Normal, Pane, Tab, etc.)
- **Clean view**: Hide it when you don't need hints for a distraction-free experience

### Layouts

#### Default Layout
Full-featured with:
- Status bar at top: Mode indicator, tabs, session name and datetime
- Keybinding hints bar at bottom: Shows available commands

#### Compact Layout
Minimal for more terminal space:
- Compact status bar: Icon-only mode indicator, compact tabs, session name
- Keybinding hints bar at bottom: Shows available commands

#### With-Hints Layout
Same as default layout - kept for backward compatibility

## Usage

### Switching Layouts
```bash
# Use default layout
zellij --layout default

# Use compact layout
zellij --layout compact
```

### Common Operations

#### Starting Zellij
```bash
zellij              # Start with default layout
zellij -s mysession # Create/attach to named session
```

#### Inside Zellij

**Option 1 - Tmux-style (Ctrl+a prefix):**
1. Press `Ctrl+a` to activate tmux mode
2. Press command key (e.g., `c` for new tab)
3. Automatically returns to normal mode

**Option 2 - Default Zellij:**
- Press `Ctrl+t` for tab mode, then `n` for new tab
- Press `Ctrl+p` for pane mode, then `d` to split down
- Press `Ctrl+s` to enter scroll mode

#### Scrollback and Search
1. `Ctrl+a [` - Enter scroll mode
2. Use `j/k` or `Ctrl+f/b` to navigate
3. Press `/` to search
4. `n/N` to jump to next/previous match
5. `q` or `Escape` to exit

## Plugins

### zjstatus
A configurable status bar plugin that provides:
- Tab management with custom formatting
- Mode indicators
- Session information
- Date/time display
- Custom colors and separators

**Repository**: https://github.com/dj95/zjstatus
**Version**: v0.21.1 (pinned for stability)

The plugin is loaded automatically from the GitHub release and doesn't require manual installation.

### Plugin Download Troubleshooting

#### macOS Plugin Loading Issues

If the plugin doesn't load on macOS (common issue), use the local file approach:

**Quick Fix (Recommended for macOS):**
```bash
# 1. Download the plugin manually
mkdir -p ~/.config/zellij/plugins
curl -L https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm \
  -o ~/.config/zellij/plugins/zjstatus.wasm

# 2. Use the local layout
zellij --layout default-local

# 3. Or set as default in config.kdl
# Change: default_layout "default"
# To:     default_layout "default-local"
```

The `default-local.kdl` layout uses `file:~/.config/zellij/plugins/zjstatus.wasm` instead of downloading from GitHub, which is more reliable on macOS.

#### Other Troubleshooting Steps

1. **Check internet connection**: Zellij needs to download the plugin on first use
2. **Clear cache**: 
   - Linux: `rm -rf ~/.cache/zellij/`
   - macOS: `rm -rf ~/Library/Caches/org.Zellij-Contributors.Zellij/`
3. **Check permissions**: Ensure `~/.config/zellij/` is writable
4. **Verify download**: Check if the file exists and is not empty:
   ```bash
   ls -lh ~/.config/zellij/plugins/zjstatus.wasm
   ```
5. **Check Zellij logs**: Look for errors in:
   - Linux: `~/.cache/zellij/`
   - macOS: `~/Library/Caches/org.Zellij-Contributors.Zellij/`

## Differences from Tmux

While matching tmux functionality and aesthetic, Zellij has some differences:

1. **Tab titles**: Currently shows tab names; command names may require additional configuration
2. **Pane borders**: Simplified UI with minimal borders by default
3. **Session management**: Built-in session manager (access with `Ctrl+a o`)
4. **Floating panes**: Native floating window support (toggle with `Ctrl+a w`)
5. **Plugin system**: WebAssembly-based plugins loaded from remote URLs

## Customization

### Changing Theme
Edit `config.kdl` and change the theme line:
```kdl
theme "catppuccin-mocha"
```

### Adding Custom Layouts
Create new `.kdl` files in the `layouts/` directory and reference them:
```bash
zellij --layout path/to/custom-layout.kdl
```

### Modifying Keybindings
Edit the `keybinds` section in `config.kdl`. Each mode can have custom bindings.

### Status Bar Customization
Edit the zjstatus plugin configuration in your layout file:
- `format_left`, `format_right`: Change what appears on status bar
- `tab_normal`, `tab_active`: Customize tab appearance
- Colors: Use Catppuccin palette hex codes

## Resources

- [Zellij Documentation](https://zellij.dev/documentation/)
- [Catppuccin Zellij Theme](https://github.com/catppuccin/zellij)
- [zjstatus Plugin](https://github.com/dj95/zjstatus)
- [Zellij Plugins](https://zellij.dev/documentation/plugins.html)

## Tips

1. **Two ways to work**: Use either `Ctrl+a` tmux-style prefix OR Zellij's default `Ctrl+<key>` modes
2. **Lock mode**: `Ctrl+g` to pass all keys to terminal (useful for nested sessions)
3. **Detach**: `Ctrl+a d` (tmux mode) or `Ctrl+o d` (session mode) to detach
4. **Tab names**: `Ctrl+a ,` (tmux mode) or `Ctrl+t r` (tab mode) to rename
5. **Scroll buffer**: 10,000 lines of scrollback history configured
6. **Default modes**: Learn Zellij's `Ctrl+p` (pane), `Ctrl+t` (tab), `Ctrl+n` (resize) for full features
