-- Separator Style Component
-- Used to visually separate groups of items

return function(variant)
  local colors = require("colors")
  local current_theme = colors:get()

  -- Default separator style
  local base = {
    icon = {
      string = "|",
      color = current_theme.border,
      padding_left = 8,
      padding_right = 8,
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
