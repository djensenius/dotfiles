# Session-scoped environment (avoid -U/universal)

# Editor and tools
set -gx EDITOR nvim
set -gx MISE_FISH_AUTO_ACTIVATE 0

# eza config
set -gx EZA_CONFIG_DIR "$HOME/.config/eza"
set -gx EZA_ICONS_AUTO true

# fzf theme/options
set -gx FZF_DEFAULT_OPTS '--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --multi'

# From your previous fish_variables (portable defaults)
set -gx BAT_THEME Catppuccin-mocha
set -gx DARK_MODE true

# gh enhance (companion of gh-dash) — pick a bubbletint theme to match Catppuccin
# https://bubbletint.dev — IDs include catppuccin_mocha, catppuccin_macchiato,
# catppuccin_frappe, catppuccin_latte
set -gx ENHANCE_THEME catppuccin_mocha

# Go module env (host-specific GOPROXY is handled in 30-host-conditional.fish)
set -gx GONOPROXY ""
set -gx GOPRIVATE ""
set -gx GONOSUMDB 'github.com/github/*'
