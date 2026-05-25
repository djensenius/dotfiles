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

-- Smooth horizontal progress bar using Unicode eighth-blocks
-- (matches the look of NSProgressIndicator / starship / cargo / uv)
local PARTIAL_BLOCKS = { "▏", "▎", "▍", "▌", "▋", "▊", "▉" }
local function progress_bar(pct, width)
	width = width or 5
	pct = math.max(0, math.min(100, pct))
	local eighths = math.floor((pct * width * 8 / 100) + 0.5)
	local full = math.floor(eighths / 8)
	local rem = eighths % 8
	local s = string.rep("█", full)
	if rem > 0 and full < width then
		s = s .. PARTIAL_BLOCKS[rem]
		s = s .. string.rep(" ", width - full - 1)
	else
		s = s .. string.rep(" ", width - full)
	end
	return s
end

-- Animated braille spinner driven by the update-status event
local SPINNER = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_state = { idx = 1 }

-- Catppuccin-mocha accent colors for progress states
local PROGRESS_COLORS = {
	normal = "#89b4fa", -- blue
	error = "#f38ba8", -- red
	indeterminate = "#f9e2af", -- yellow
}

-- Returns a wezterm format-list (or nil) for the progress portion of a tab title.
-- The indeterminate spinner uses a static glyph here (format-tab-title doesn't
-- reliably re-fire on a timer); the *animated* spinner lives in the window's
-- left status bar, driven by update-status below.
local function progress_format(pane_info)
	local p = pane_info.progress
	if not p or p == "None" then
		return nil
	end
	if type(p) == "table" then
		if p.Percentage ~= nil then
			return {
				{ Foreground = { Color = PROGRESS_COLORS.normal } },
				{ Text = "  " .. progress_bar(p.Percentage) .. " " .. p.Percentage .. "%" },
				"ResetAttributes",
			}
		elseif p.Error ~= nil then
			return {
				{ Foreground = { Color = PROGRESS_COLORS.error } },
				{ Text = "  " .. wezterm.nerdfonts.md_alert_circle .. " " .. (p.Error or 0) .. "%" },
				"ResetAttributes",
			}
		end
	elseif p == "Indeterminate" then
		return {
			{ Foreground = { Color = PROGRESS_COLORS.indeterminate } },
			{ Text = "  " .. wezterm.nerdfonts.md_dots_horizontal },
			"ResetAttributes",
		}
	end
	return nil
end

wezterm.on("format-tab-title", function(tab)
	local title = tab_title(tab)
	local progress = progress_format(tab.active_pane)
	local bell = tab.active_pane.has_unseen_output and (" " .. wezterm.nerdfonts.cod_bell) or ""

	local out = { { Text = " " .. title } }
	if progress then
		for _, item in ipairs(progress) do
			table.insert(out, item)
		end
	end
	table.insert(out, { Text = bell .. " " })
	return out
end)

-- Returns true if any pane in this window currently has indeterminate progress
local function any_indeterminate(window)
	local mux_win = window:mux_window()
	if not mux_win then
		return false
	end
	for _, tab in ipairs(mux_win:tabs()) do
		for _, pane in ipairs(tab:panes()) do
			if pane.get_progress and pane:get_progress() == "Indeterminate" then
				return true
			end
		end
	end
	return false
end

-- Animated spinner in the right status bar.
-- set_right_status with a new value forces the status to re-render, which is
-- what gives us reliable animation. Right-side has fewer UI elements to
-- overlap with than the left (which sits next to the traffic lights). When
-- nothing is spinning we clear the status once and skip further work, so
-- idle CPU cost stays at ~0.
wezterm.on("update-status", function(window)
	if any_indeterminate(window) then
		spinner_state.idx = (spinner_state.idx % #SPINNER) + 1
		window:set_right_status(wezterm.format({
			{ Foreground = { Color = PROGRESS_COLORS.indeterminate } },
			{ Text = " " .. SPINNER[spinner_state.idx] .. " " },
			"ResetAttributes",
		}))
	elseif spinner_state.idx ~= 0 then
		spinner_state.idx = 0
		window:set_right_status("")
	end
end)

-- 60 fps spinner animation (only redraws when something is actually animating)
config.status_update_interval = 16

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
