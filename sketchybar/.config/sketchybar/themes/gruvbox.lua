-- Gruvbox Dark Theme
return {
  name = "gruvbox",
  bar_style = "opaque",  -- Cardboard/cork board aesthetic - warm, solid, grounded

  -- Base colors (original names for backwards compatibility)
  black = 0xff282828,     -- bg0
  white = 0xffebdbb2,     -- fg0
  red = 0xfffb4934,       -- bright_red
  green = 0xffb8bb26,     -- bright_green
  blue = 0xff83a598,      -- bright_blue
  yellow = 0xfffabd2f,    -- bright_yellow
  orange = 0xfffe8019,    -- bright_orange
  magenta = 0xffd3869b,   -- bright_purple
  grey = 0xff928374,      -- gray
  transparent = 0x00000000,

  -- Semantic colors (NEW - for better component styling)
  accent = 0xff83a598,    -- bright_blue
  surface = 0xff3c3836,   -- bg1
  border = 0xff504945,    -- bg2
  text = 0xffebdbb2,      -- fg0
  text_muted = 0xff928374, -- gray
  success = 0xffb8bb26,   -- bright_green
  warning = 0xfffabd2f,   -- bright_yellow
  error = 0xfffb4934,     -- bright_red

  -- Bar colors
  bar = {
    bg = 0xf01d2021,      -- bg0_h with opacity
    border = 0xff3c3836,   -- bg1
  },
  popup = {
    bg = 0xe01d2021,      -- bg0_h with less opacity
    border = 0xff504945    -- bg2
  },

  -- Surface colors
  bg1 = 0xff3c3836,       -- bg1
  bg2 = 0xff504945,       -- bg2

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
