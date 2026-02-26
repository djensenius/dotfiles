# Session-scoped environment (avoid -U/universal)

# Editor and tools
set -gx EDITOR nvim

# eza config
set -gx EZA_CONFIG_DIR "$HOME/.config/eza"
set -gx EZA_ICONS_AUTO true

# fzf theme/options (colors are set dynamically by 01-theme.fish)

# From your previous fish_variables (portable defaults)
# BAT_THEME, DARK_MODE, and FZF_DEFAULT_OPTS are now managed by 01-theme.fish

# Go module env (host-specific GOPROXY is handled in 30-host-conditional.fish)
set -gx GONOPROXY ""
set -gx GOPRIVATE ""
set -gx GONOSUMDB 'github.com/github/*'
