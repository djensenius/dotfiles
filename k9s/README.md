# k9s Configuration

This configuration provides a Catppuccin Mocha theme for [k9s](https://k9scli.io/), the Kubernetes CLI to manage your clusters in style.

## Installation

Symlink the k9s directory to your home config:

```bash
ln -sf $(pwd)/k9s ~/.config/k9s
```

## Features

- **Catppuccin Mocha theme**: Consistent with other tools in this dotfiles repository
- **Optimized colors**: Carefully mapped Catppuccin colors for all k9s UI elements
- **Enhanced readability**: Proper contrast ratios for accessibility
- **Resource status colors**: Intuitive color coding for Kubernetes resource states

## Files

- `config.yaml`: Main k9s configuration with theme reference
- `skins/catppuccin-mocha.yaml`: Complete Catppuccin Mocha skin definition

## Color Mapping

The theme uses the standard Catppuccin Mocha palette:
- **Background**: `#1e1e2e` (base)
- **Text**: `#cdd6f4` (text)
- **Accents**: `#89b4fa` (blue), `#a6e3a1` (green), `#f38ba8` (red), `#f9e2af` (yellow)
- **Surfaces**: `#313244` (surface0), `#45475a` (surface1), `#585b70` (surface2)