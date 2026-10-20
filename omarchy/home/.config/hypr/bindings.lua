-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Launch the local Herdr 0.9 build whose session navigator uses clean
-- indentation instead of the hard-coded tree branch glyphs.
-- Night light was bound to the stock toggle, which turns on at 4000 K.
hl.unbind("SUPER + CTRL + N")
o.bind("SUPER + CTRL + N", "Toggle nightlight", "omarchy-shell nightlight toggle")

hl.unbind("SUPER + CTRL + RETURN")
o.bind(
  "SUPER + CTRL + RETURN",
  "Herdr (clean navigator)",
  { tui = "/home/charlesmowbray/.local/lib/herdr-no-tree/0.9.0/herdr" }
)

-- SUPER+F was Omarchy's original full screen; keep that mode on
-- SUPER+CTRL+ALT+F.
hl.unbind("SUPER + F")
o.bind(
  "SUPER + F",
  "Full screen with browser tabs",
  function()
    local window = hl.get_active_window()
    if not window then return end

    if window.fullscreen == 2 then
      hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0, action = "set" }))
    else
      hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "set" }))
    end
  end
)
hl.unbind("SUPER + CTRL + ALT + F")
o.bind(
  "SUPER + CTRL + ALT + F",
  "Full screen (original)",
  hl.dsp.window.fullscreen({ mode = "fullscreen" })
)

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")
