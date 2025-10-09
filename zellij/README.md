# Zellij Configuration

Clean, minimal Zellij terminal multiplexer configuration with Catppuccin Mocha theme and tmux-style keybindings.

## Features

- **🎨 Catppuccin Mocha Theme**: Matches tmux catppuccin theme colors
- **📍 Status Bar at Top**: Displays mode, tabs, and datetime with nerd fonts
- **📝 Command-Based Tab Names**: Shows running command in tab (like tmux)
- **⌨️ Tmux-style Keybindings**: Familiar Ctrl+a prefix
- **🔀 Vim Navigation**: Navigate panes with h/j/k/l
- **💾 Local Plugin**: Uses local zjstatus.wasm file for reliability
- **🎯 Rounded Corners**: Smooth powerline separators  matching tmux

## Installation

The plugin is automatically downloaded during setup:

```bash
./install.sh  # Installs zjstatus plugin to ~/.config/zellij/plugins/
```

## Usage

```bash
# Start Zellij with default layout
zellij

# Common keybindings (after Ctrl+a prefix):
# h/j/k/l  - Navigate panes
# |        - Split pane vertically
# -        - Split pane horizontally  
# x        - Close pane
# z        - Toggle fullscreen
# c        - New tab
# p/n      - Previous/next tab
# 1-9      - Go to tab number
# ,        - Rename tab
# [        - Scroll mode
```

## File Structure

```
zellij/
├── config.kdl                   # Main configuration
├── layouts/default.kdl          # Status bar layout
└── themes/catppuccin-mocha.kdl  # Catppuccin Mocha theme
```

## Customization

### Change Default Layout

Edit `config.kdl`:
```kdl
default_layout "default"
```

### Adjust Colors

The theme is defined in `themes/catppuccin-mocha.kdl` using the Catppuccin Mocha palette:
- Base: #1e1e2e (background)
- Surface0: #313244 (inactive tabs)
- Blue: #89b4fa (active elements)
- Text: #cdd6f4 (foreground)

### Keybindings

All keybindings are in `config.kdl`. The configuration uses:
- Zellij's default keybindings for all modes (Ctrl+p, Ctrl+t, etc.)
- Additional tmux mode activated with Ctrl+a

## Troubleshooting

### Plugin Not Loading

Ensure the plugin is downloaded:
```bash
ls ~/.config/zellij/plugins/zjstatus.wasm
```

If missing, download manually:
```bash
mkdir -p ~/.config/zellij/plugins
curl -L https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm \
  -o ~/.config/zellij/plugins/zjstatus.wasm
```

### Status Bar Not Showing

Check that you're using the default layout:
```bash
zellij --layout default
```

## Recommended Plugins

To further match your tmux configuration, consider these Zellij plugins:

### Already Included
- **zjstatus** - Custom status bar (installed automatically)

### Additional Plugins Worth Exploring

1. **[zellij-forgot](https://github.com/karimould/zellij-forgot)** - Keybinding hints similar to tmux-which-key
   ```bash
   # Download to ~/.config/zellij/plugins/
   ```

2. **[room](https://github.com/rvcas/room)** - Session switcher similar to tmux-sessionx
   ```bash
   # Quick session navigation
   ```

3. **[harpoon](https://github.com/Nacho114/harpoon)** - Quick file/project jumping
   ```bash
   # Similar to tmux session management
   ```

4. **[monocle](https://github.com/imsnif/monocle)** - Text search and copy similar to tmux-thumbs
   ```bash
   # Built-in to Zellij, use Ctrl+s to activate
   ```

### Tmux Features Already Built Into Zellij
- **Session management**: Native in Zellij (use `zellij attach` or Ctrl+o)
- **Pane navigation**: vim-tmux-navigator equivalent built-in
- **Copy mode**: Built-in with `Ctrl+s` (scroll mode)
- **Search**: Built-in with `/` in scroll mode
- **Floating panes**: Native Zellij feature (Ctrl+p w to toggle)

## References

- [Zellij Documentation](https://zellij.dev)
- [zjstatus Plugin](https://github.com/dj95/zjstatus)
- [Catppuccin Theme](https://github.com/catppuccin/catppuccin)
- [Zellij Plugin System](https://zellij.dev/documentation/plugins)
