-- Tokyo Night Theme
return {
  -- Base colors
  black = 0xff15161e,     -- bg_dark
  white = 0xffc0caf5,     -- fg
  red = 0xfff7768e,       -- red
  green = 0xff9ece6a,     -- green
  blue = 0xff7aa2f7,      -- blue
  yellow = 0xffe0af68,    -- yellow
  orange = 0xffff9e64,    -- orange
  magenta = 0xffbb9af7,   -- magenta
  grey = 0xff565f89,      -- comment
  transparent = 0x00000000,

  -- Bar colors
  bar = {
    bg = 0xf01a1b26,      -- bg with opacity
    border = 0xff24283b,   -- bg_highlight
  },
  popup = {
    bg = 0xe01a1b26,      -- bg with less opacity
    border = 0xff414868    -- bg_visual
  },

  -- Surface colors
  bg1 = 0xff24283b,       -- bg_highlight
  bg2 = 0xff414868,       -- terminal_black

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}