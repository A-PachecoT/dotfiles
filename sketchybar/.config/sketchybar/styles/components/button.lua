-- Button Style Component
-- Used for clickable items, controls, and interactive elements

return function(variant)
  local colors = require("colors")
  local current_theme = colors:get()

  -- Default button style
  local base = {
    icon = {
      padding_left = 8,
      padding_right = 8,
      color = current_theme.text,
    },
    label = {
      padding_right = 12,
      color = current_theme.text_muted,
    },
    background = {
      color = current_theme.surface,
      border_color = current_theme.border,
      border_width = 1,
      height = 26,
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
