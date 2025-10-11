-- Bar Layout Style
-- Top-level bar styling

return function()
  local colors = require("colors")
  local current_theme = colors:get()

  return {
    position = "top",
    height = 40,
    margin = 0,
    y_offset = 0,
    padding_left = 10,
    padding_right = 10,
    color = current_theme.bar.bg,
    border_color = current_theme.bar.border,
    shadow = "off",
    topmost = "off",
    sticky = "on",
    font_smoothing = "on",
  }
end
