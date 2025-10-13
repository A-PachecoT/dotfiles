-- Card Style Component
-- Used for workspace indicators, media players, and other contained elements

return function(variant)
  local colors = require("colors")
  local current_theme = colors.get and colors:get() or colors

  -- Get theme-specific component styling or use defaults
  local style = current_theme.component_style or {
    corner_radius = 0,
    border_width = 1,
    card_height = 26,
    padding = 10,
  }

  -- Default card style with theme-specific properties
  local base = {
    background = {
      color = current_theme.surface,
      border_color = current_theme.border,
      border_width = style.border_width,
      height = style.card_height,
      corner_radius = style.corner_radius,
    },
    padding_left = style.padding + 5,
    padding_right = style.padding - 2,
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
