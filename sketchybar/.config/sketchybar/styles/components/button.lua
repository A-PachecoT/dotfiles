-- Button Style Component
-- Used for clickable items, controls, and interactive elements

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

  -- Default button style with theme-specific properties
  local base = {
    icon = {
      padding_left = style.padding - 2,
      padding_right = style.padding - 2,
      color = current_theme.text,
    },
    label = {
      padding_right = style.padding + 2,
      color = current_theme.text_muted,
    },
    background = {
      color = current_theme.surface,
      border_color = current_theme.border,
      border_width = style.border_width,
      height = style.card_height,
      corner_radius = style.corner_radius,
    },
    padding_left = 1,
    padding_right = 1,
  }

  -- Variant modifications
  if variant == "primary" then
    base.background.color = current_theme.accent
    base.background.border_color = current_theme.accent
    base.icon.color = current_theme.white
    base.label.color = current_theme.white
  elseif variant == "ghost" then
    base.background.color = current_theme.transparent
    base.background.border_width = 0
  elseif variant == "outline" then
    base.background.color = current_theme.transparent
  end

  return base
end
