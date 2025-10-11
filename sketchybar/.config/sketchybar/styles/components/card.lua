-- Card Style Component
-- Used for workspace indicators, media players, and other contained elements

return function(variant)
  local colors = require("colors")
  local current_theme = colors:get()

  -- Default card style
  local base = {
    background = {
      color = current_theme.surface,
      border_color = current_theme.border,
      border_width = 1,
      height = 26,
      corner_radius = 0,
    },
    padding_left = 15,
    padding_right = 8,
  }

  -- Variant modifications
  if variant == "elevated" then
    base.background.border_width = 2
    base.background.height = 28
  elseif variant == "flat" then
    base.background.border_width = 0
    base.background.color = current_theme.transparent
  elseif variant == "highlighted" then
    base.background.color = current_theme.accent
    base.background.border_color = current_theme.accent
  end

  return base
end
