-- Catppuccin Mocha Theme
return {
  name = "catppuccin",

  -- Base colors (original names for backwards compatibility)
  black = 0xff11111b,     -- Crust
  white = 0xffcdd6f4,     -- Text
  red = 0xfff38ba8,       -- Red
  green = 0xffa6e3a1,     -- Green
  blue = 0xff89b4fa,      -- Blue
  yellow = 0xfff9e2af,    -- Yellow
  orange = 0xfffab387,    -- Peach
  magenta = 0xffcba6f7,   -- Mauve
  grey = 0xff6c7086,      -- Overlay0
  transparent = 0x00000000,

  -- Semantic colors (NEW - for better component styling)
  accent = 0xff89b4fa,    -- Blue
  surface = 0xff313244,   -- Surface0
  border = 0xff45475a,    -- Surface1
  text = 0xffcdd6f4,      -- Text
  text_muted = 0xff6c7086, -- Overlay0
  success = 0xffa6e3a1,   -- Green
  warning = 0xfff9e2af,   -- Yellow
  error = 0xfff38ba8,     -- Red

  -- Bar colors
  bar = {
    bg = 0xf01e1e2e,      -- Base with opacity
    border = 0xff45475a,   -- Surface0
  },
  popup = {
    bg = 0xe01e1e2e,      -- Base with less opacity
    border = 0xff585b70    -- Surface1
  },

  -- Surface colors
  bg1 = 0xff313244,       -- Surface0
  bg2 = 0xff45475a,       -- Surface1

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
