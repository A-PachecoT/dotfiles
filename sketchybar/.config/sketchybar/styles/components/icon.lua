-- Icon Style Component
-- Default icon styling for consistency

return function(variant)
  local colors = require("colors")
  local settings = require("settings")
  local current_theme = colors.get and colors:get() or colors

  -- Get theme-specific component styling or use defaults
  local style = current_theme.component_style or {
    corner_radius = 0,
    border_width = 1,
    card_height = 26,
    padding = 10,
  }

  -- Default icon style with theme-specific padding
  local base = {
    icon = {
      font = settings.font.text,
      color = current_theme.text,
      padding_left = style.padding - 2,
      padding_right = style.padding - 2,
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
