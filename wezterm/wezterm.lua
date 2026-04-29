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
local process_icons = {
	["nvim"] = wezterm.nerdfonts.custom_vim,
	["vim"] = wezterm.nerdfonts.custom_vim,
	["node"] = wezterm.nerdfonts.dev_nodejs_small,
	["npm"] = wezterm.nerdfonts.dev_npm,
	["yarn"] = wezterm.nerdfonts.seti_yarn,
	["python"] = wezterm.nerdfonts.dev_python,
	["python3"] = wezterm.nerdfonts.dev_python,
	["ruby"] = wezterm.nerdfonts.dev_ruby,
	["go"] = wezterm.nerdfonts.dev_go,
	["cargo"] = wezterm.nerdfonts.dev_rust,
	["fish"] = wezterm.nerdfonts.dev_terminal,
	["bash"] = wezterm.nerdfonts.dev_terminal,
	["zsh"] = wezterm.nerdfonts.dev_terminal,
	["ssh"] = wezterm.nerdfonts.md_console_network,
	["git"] = wezterm.nerdfonts.dev_git,
	["lazygit"] = wezterm.nerdfonts.dev_git,
	["yazi"] = wezterm.nerdfonts.md_folder_open,
	["btm"] = wezterm.nerdfonts.md_chart_areaspline,
	["docker"] = wezterm.nerdfonts.linux_docker,
	["make"] = wezterm.nerdfonts.seti_makefile,
}

local function process_icon(pane_info)
	local proc = pane_info.foreground_process_name or ""
	proc = proc:match("([^/\\]+)$") or proc
	return process_icons[proc] or wezterm.nerdfonts.cod_terminal
end

local function tab_title(tab_info)
	local title = tab_info.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	-- Otherwise, use the title from the active pane in that tab
	local pane_title = tab_info.active_pane.title or ""
	if pane_title:find("codespaces") ~= nil then
		return ""
	elseif pane_title:find("^pt") ~= nil then
		return ""
	elseif pane_title:find("server") ~= nil then
		return "  " .. pane_title
	elseif pane_title:find("pi") ~= nil then
		return "  " .. pane_title
	end

	return process_icon(tab_info.active_pane) .. "  " .. pane_title
end

-- Progress glyphs (filled circle slices) for OSC 9;4 progress
local PCT_GLYPHS = {
	wezterm.nerdfonts.md_circle_slice_1,
	wezterm.nerdfonts.md_circle_slice_2,
	wezterm.nerdfonts.md_circle_slice_3,
	wezterm.nerdfonts.md_circle_slice_4,
	wezterm.nerdfonts.md_circle_slice_5,
	wezterm.nerdfonts.md_circle_slice_6,
	wezterm.nerdfonts.md_circle_slice_7,
	wezterm.nerdfonts.md_circle_slice_8,
}

local function progress_suffix(pane_info)
	if not pane_info.pane_id then
		return ""
	end
	local mux_pane = wezterm.mux.get_pane(pane_info.pane_id)
	if not mux_pane or not mux_pane.get_progress then
		return ""
	end
	local p = mux_pane:get_progress()
	if type(p) == "table" then
		if p.Percentage then
			local idx = math.min(8, math.max(1, math.ceil(p.Percentage / 12.5)))
			return " " .. PCT_GLYPHS[idx] .. " " .. p.Percentage .. "%"
		elseif p.Error then
			return " " .. wezterm.nerdfonts.md_alert_circle
		end
	elseif p == "Indeterminate" then
		return " " .. wezterm.nerdfonts.md_loading
	end
	return ""
end

wezterm.on("format-tab-title", function(tab)
	local title = tab_title(tab)
	local progress = progress_suffix(tab.active_pane)
	local bell = tab.active_pane.has_unseen_output and (" " .. wezterm.nerdfonts.cod_bell) or ""
	return {
		{ Text = " " .. title .. progress .. bell .. " " },
	}
end)

-- Use the macOS-native fancy tab bar with integrated traffic lights
config.use_fancy_tab_bar = true
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_button_style = "MacOsNative"
config.show_new_tab_button_in_tab_bar = true
-- Always show the tab bar so the integrated traffic lights have a place to live
config.hide_tab_bar_if_only_one_tab = false

-- Title-bar / fancy tab bar styling (matches OLED Catppuccin theme)
config.window_frame = {
	font = wezterm.font({ family = "Monaspace Neon Var", weight = "Medium" }),
	font_size = 13.0,
	active_titlebar_bg = "#040404",
	inactive_titlebar_bg = "#040404",
}

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
