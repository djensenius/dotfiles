-- I use a custom icon from: git@github.com:mikker/wezterm-icon.git
-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Colour scheme
config.color_scheme = "Catppuccin Mocha"
local custom = wezterm.color.get_builtin_schemes()["Catppuccin Mocha"]
custom.background = "#000000"
custom.tab_bar.background = "#040404"
custom.tab_bar.inactive_tab.bg_color = "#0f0f0f"
custom.tab_bar.new_tab.bg_color = "#080808"
config.color_schemes = {
    ["OLEDppuccin"] = custom,
}
config.color_scheme = "OLEDppuccin"


-- Fonts
-- config.experimental_svg_fonts = true
config.font = wezterm.font_with_fallback {
  "Monaspace Neon Var",
  "JetBrains Mono",
  "Fira Code",
  "Hack Nerd Font",
  {
    family = "Apple Color Emoji",
    assume_emoji_presentation = true,
    scale = 2,
  }
}
config.line_height = 1.2

config.allow_square_glyphs_to_overflow_width = 'Always'

config.font_rules = {
  {
    intensity = 'Bold',
    italic = true,
    font = wezterm.font {
      family = 'Monaspace Xenon Var',
      weight = 'Bold',
      style = 'Italic',
    },
  },
  {
    italic = true,
    intensity = 'Half',
    font = wezterm.font {
      family = 'Monaspace Xenon Var',
      weight = 'DemiBold',
      style = 'Italic',
    },
  },
  {
    italic = true,
    intensity = 'Normal',
    font = wezterm.font {
      family = 'Monaspace Xenon Var',
      style = 'Italic',
    },
  },
}

config.font_size = 14.0
config.harfbuzz_features = { "ss01=1", "ss02=1", "ss03=1", "ss04=1", "ss05=1", "ss06=1", "ss07=1", "dlig=1", "calt=1" }

-- Tabs
local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  if tab_info.active_pane.title and tab_info.active_pane.title:find("^gh ssh") ~= nil then
    return ''
  elseif tab_info.active_pane.title and tab_info.active_pane.title:find("^pt") ~= nil then
    return ''
  elseif tab_info.active_pane.title and tab_info.active_pane.title:find("server") ~= nil then
    return '  ' .. tab_info.active_pane.title
  elseif tab_info.active_pane.title and tab_info.active_pane.title:find("pi") ~= nil then
    return '  ' .. tab_info.active_pane.title
  end

  return '  ' .. tab_info.active_pane.title
end

wezterm.on(
  'format-tab-title',
  function(tab)
    local title = tab_title(tab)
    if tab.is_active then
      return {
        { Text = ' ' .. title .. ' ' },
      }
    end
    return title
  end
)
config.hide_tab_bar_if_only_one_tab = true

config.window_decorations = "RESIZE"

-- Other stuff
config.quit_when_all_windows_are_closed = false
config.window_close_confirmation = "NeverPrompt"
config.initial_rows = 40
config.initial_cols = 120
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

return config
