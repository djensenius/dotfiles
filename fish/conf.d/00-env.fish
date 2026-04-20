# Session-scoped environment (avoid -U/universal)

# Editor and tools
set -gx EDITOR nvim

# eza config
set -gx EZA_CONFIG_DIR "$HOME/.config/eza"
set -gx EZA_ICONS_AUTO true

# fzf theme/options (colors are set dynamically by 01-theme.fish)

# bat: auto-detect terminal dark/light mode (no manual switching needed)
set -gx BAT_THEME "auto:system"
set -gx BAT_THEME_DARK "Catppuccin Mocha"
set -gx BAT_THEME_LIGHT "Catppuccin Latte"

# DARK_MODE and FZF_DEFAULT_OPTS are managed by 99-theme.fish

# Go module env (host-specific GOPROXY is handled in 30-host-conditional.fish)
set -gx GONOPROXY ""
set -gx GOPRIVATE ""
set -gx GONOSUMDB 'github.com/github/*'
