-- Bar Layout Style
-- Top-level bar styling with variants

return function(variant)
  local colors = require("colors")

  -- Get base color from theme
  local base_color = colors.bar and colors.bar.bg or 0xf01a1b26
  local base_border = colors.bar and colors.bar.border or 0xff24283b

  -- Extract RGB from color
  local rgb = base_color & 0x00ffffff

  -- Base configuration
  local config = {
    position = "top",
    height = 40,
    margin = 0,
    y_offset = 0,
    padding_left = 10,
    padding_right = 10,
    shadow = "off",
    topmost = "off",
    sticky = "on",
    font_smoothing = "on",
  }

  -- Apply variant styles
  variant = variant or "solid"

  if variant == "solid" then
    -- Default: Current style (medium opacity)
    config.color = base_color
    config.border_color = base_border

  elseif variant == "transparent" then
    -- More transparent background
    config.color = rgb | 0xa0000000  -- ~63% opacity
    config.border_color = rgb | 0x40000000  -- ~25% opacity

  elseif variant == "minimal" then
    -- Very subtle, almost invisible
    config.color = rgb | 0x30000000  -- ~19% opacity
    config.border_color = rgb | 0x20000000  -- ~13% opacity

  elseif variant == "opaque" then
    -- Completely solid
    config.color = rgb | 0xff000000  -- 100% opacity
    config.border_color = base_border | 0xff000000

  elseif variant == "blur" then
    -- Frosted glass effect
    config.color = rgb | 0x60000000  -- ~38% opacity
    config.border_color = rgb | 0x40000000
    config.blur_radius = 30
    config.shadow = "on"

  elseif variant == "floating" then
    -- Floating bar with shadow, rounded edges, and border
    config.color = base_color
    config.border_color = base_border
    config.border_width = 2
    config.corner_radius = 9
    config.shadow = "on"
    config.margin = 10
    config.y_offset = 5
    config.padding_left = 15
    config.padding_right = 15

  end

  return config
end
