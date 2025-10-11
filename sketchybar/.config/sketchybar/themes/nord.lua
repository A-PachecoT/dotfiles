-- Nord Theme
return {
  name = "nord",

  -- Base colors (original names for backwards compatibility)
  black = 0xff2e3440,     -- nord0
  white = 0xffe5e9f0,     -- nord6
  red = 0xffbf616a,       -- nord11
  green = 0xffa3be8c,     -- nord14
  blue = 0xff81a1c1,      -- nord9
  yellow = 0xffebcb8b,    -- nord13
  orange = 0xffd08770,    -- nord12
  magenta = 0xffb48ead,   -- nord15
  grey = 0xff4c566a,      -- nord3
  transparent = 0x00000000,

  -- Semantic colors (NEW - for better component styling)
  accent = 0xff81a1c1,    -- nord9 (blue)
  surface = 0xff3b4252,   -- nord1
  border = 0xff434c5e,    -- nord2
  text = 0xffe5e9f0,      -- nord6
  text_muted = 0xff4c566a, -- nord3
  success = 0xffa3be8c,   -- nord14 (green)
  warning = 0xffebcb8b,   -- nord13 (yellow)
  error = 0xffbf616a,     -- nord11 (red)

  -- Bar colors
  bar = {
    bg = 0xf02e3440,      -- nord0 with opacity
    border = 0xff3b4252,   -- nord1
  },
  popup = {
    bg = 0xe02e3440,      -- nord0 with less opacity
    border = 0xff434c5e    -- nord2
  },

  -- Surface colors
  bg1 = 0xff3b4252,       -- nord1
  bg2 = 0xff434c5e,       -- nord2

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
