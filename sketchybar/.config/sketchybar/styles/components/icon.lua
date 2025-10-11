-- Icon Style Component
-- Default icon styling for consistency

return function(variant)
  local colors = require("colors")
  local settings = require("settings")
  local current_theme = colors:get()

  -- Default icon style
  local base = {
    icon = {
      font = settings.font.text,
      color = current_theme.text,
      padding_left = 8,
      padding_right = 8,
    },
  }

  -- Variant modifications
  if variant == "large" then
    base.icon.font = { size = 18 }
  elseif variant == "small" then
    base.icon.font = { size = 12 }
  elseif variant == "muted" then
    base.icon.color = current_theme.text_muted
  elseif variant == "accent" then
    base.icon.color = current_theme.accent
  end

  return base
end
