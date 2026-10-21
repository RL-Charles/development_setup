-- WezTerm renders with FreeType on Windows, so text matches Omarchy's look
-- (grayscale antialiasing, slight hinting) more closely than Windows Terminal.
local wezterm = require 'wezterm'

return {
  default_domain = 'WSL:Ubuntu',
  default_cwd = '~',

  font = wezterm.font 'JetBrainsMono Nerd Font',
  font_size = 9,
  freetype_load_target = 'Light',   -- slight hinting, as on Omarchy
  freetype_render_target = 'Light', -- grayscale; subpixel fringes on OLED
  front_end = 'WebGpu',

  color_scheme = 'Catppuccin Mocha',
  window_padding = { left = 14, right = 14, top = 14, bottom = 14 },
  hide_tab_bar_if_only_one_tab = true,
  enable_scroll_bar = false,
  check_for_updates = false,
}
