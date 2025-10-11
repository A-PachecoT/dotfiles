-- Popup Layout Style
-- Styling for popup menus and overlays

return function()
  local colors = require("colors")
  local current_theme = colors:get()

  return {
    background = {
      color = current_theme.popup.bg,
      border_color = current_theme.popup.border,
      border_width = 2,
      corner_radius = 8,
      shadow = {
        drawing = true,
        color = current_theme.black,
        alpha = 0.3,
        angle = 0,
        distance = 5,
      },
    },
    blur_radius = 30,
  }
end
