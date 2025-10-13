-- Badge Style Component
-- Used for notifications, counters, and status indicators

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

  -- Badges are pill-shaped, use corner_radius for roundness
  -- Gruvbox will be less rounded, Tokyo Night very rounded
  local badge_radius = math.max(style.corner_radius, 9)  -- Minimum 9 for pill shape

  -- Default badge style with theme-specific properties
  local base = {
    icon = {
      padding_left = 6,
      padding_right = 6,
      color = current_theme.white,
      font = { size = 10 },
    },
    label = {
      drawing = false,
    },
    background = {
      color = current_theme.accent,
      height = 18,
      corner_radius = badge_radius,
    },
    padding_left = 2,
    padding_right = 2,
  }

  -- Variant modifications
  if variant == "success" then
    base.background.color = current_theme.success
  elseif variant == "warning" then
    base.background.color = current_theme.warning
  elseif variant == "error" then
    base.background.color = current_theme.error
  elseif variant == "muted" then
    base.background.color = current_theme.grey
  end

  return base
end
