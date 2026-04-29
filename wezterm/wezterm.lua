-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Colour scheme - Catppuccin Mocha with OLED-friendly customizations
local custom = wezterm.color.get_builtin_schemes()["Catppuccin Mocha"]
custom.background = "#000000"
custom.tab_bar.background = "#040404"
custom.tab_bar.inactive_tab.bg_color = "#0f0f0f"
custom.tab_bar.new_tab.bg_color = "#080808"
config.color_schemes = {
	["OLEDppuccin"] = custom,
}
config.color_scheme = "OLEDppuccin"

-- Fonts - Monaspace variable fonts with NF (Nerd Font) fallback for icons
config.font = wezterm.font_with_fallback({
	{
		family = "Monaspace Neon Var",
		weight = "Light",
	},
	{
		family = "Monaspace Neon NF",
		scale = 1.2,
	},
	"JetBrains Mono",
	"Fira Code",
	{
		family = "Apple Color Emoji",
		assume_emoji_presentation = true,
		scale = 2,
	},
})

-- Use cap-height scaling for fallback fonts (helps nerd font icons match)
config.use_cap_height_to_scale_fallback_fonts = true

config.font_size = 15.0
config.line_height = 1.2
config.allow_square_glyphs_to_overflow_width = "Always"

-- Fix for Monaspace ligature rendering issues (per Wezterm maintainer)
-- See: https://github.com/wez/wezterm/issues/4874
config.freetype_load_flags = "NO_HINTING"

-- OpenType features - enable ligatures and Monaspace texture healing
config.harfbuzz_features = {
	"calt=1",
	"liga=1",
	"dlig=1",
	"ss01=1",
	"ss02=1",
	"ss03=1",
	"ss04=1",
	"ss05=1",
	"ss06=1",
	"ss09=1",
}

-- Font rules for different styles using Monaspace variants
config.font_rules = {
	{
		intensity = "Bold",
		italic = true,
		font = wezterm.font({
			family = "Monaspace Krypton Var",
			weight = "Bold",
			style = "Italic",
		}),
	},
	{
		italic = true,
		intensity = "Half",
		font = wezterm.font({
			family = "Monaspace Radon Var",
			weight = "DemiBold",
			style = "Italic",
		}),
	},
	{
		italic = true,
		intensity = "Normal",
		font = wezterm.font({
			family = "Monaspace Radon Var",
			style = "Italic",
		}),
	},
	{
		intensity = "Bold",
		italic = false,
		font = wezterm.font({
			family = "Monaspace Xenon Var",
			weight = "Bold",
		}),
	},
}

-- Tabs
local function tab_title(tab_info)
	local title = tab_info.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	-- Otherwise, use the title from the active pane in that tab
	if tab_info.active_pane.title and tab_info.active_pane.title:find("codespaces") ~= nil then
		return ""
	elseif tab_info.active_pane.title and tab_info.active_pane.title:find("^pt") ~= nil then
		return ""
	elseif tab_info.active_pane.title and tab_info.active_pane.title:find("server") ~= nil then
		return "  " .. tab_info.active_pane.title
	elseif tab_info.active_pane.title and tab_info.active_pane.title:find("pi") ~= nil then
		return "  " .. tab_info.active_pane.title
	end

	return "  " .. tab_info.active_pane.title
end

wezterm.on("format-tab-title", function(tab)
	local title = tab_title(tab)
	if tab.is_active then
		return {
			{ Text = " " .. title .. " " },
		}
	end
	return title
end)

config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

-- Make URLs, commit SHAs, issue refs, etc. clickable
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Better key reporting (CSI u) so nvim/tmux see modifiers like Ctrl+Shift+...
config.enable_kitty_keyboard = true

-- Quality-of-life
config.scrollback_lines = 10000
config.audible_bell = "Disabled"

-- Window configuration
config.quit_when_all_windows_are_closed = false
config.window_close_confirmation = "NeverPrompt"
config.initial_rows = 40
config.initial_cols = 120
config.window_padding = {
	left = 0,
	right = 0,
	top = 10,
	bottom = 10,
}

return config
