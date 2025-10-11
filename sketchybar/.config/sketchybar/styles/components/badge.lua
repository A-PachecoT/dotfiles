-- Badge Style Component
-- Used for notifications, counters, and status indicators

return function(variant)
  local colors = require("colors")
  local current_theme = colors:get()

  -- Default badge style
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
      corner_radius = 9,
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
