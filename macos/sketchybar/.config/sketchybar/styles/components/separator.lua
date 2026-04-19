-- Separator Style Component
-- Used to visually separate groups of items

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

  -- Default separator style with theme-specific padding
  local base = {
    icon = {
      string = "|",
      color = current_theme.border,
      padding_left = style.padding - 2,
      padding_right = style.padding - 2,
    },
    label = {
      drawing = false,
    },
    background = {
      color = current_theme.transparent,
    },
  }

  -- Variant modifications
  if variant == "bold" then
    base.icon.string = "│"
    base.icon.color = current_theme.text_muted
  elseif variant == "dotted" then
    base.icon.string = "·"
  elseif variant == "space" then
    base.icon.string = " "
    base.icon.padding_left = 16
    base.icon.padding_right = 16
  end

  return base
end
