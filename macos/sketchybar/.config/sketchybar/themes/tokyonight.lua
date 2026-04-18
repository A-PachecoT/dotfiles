-- Tokyo Night Theme
return {
  name = "tokyonight",
  bar_style = "blur",  -- Cyberpunk glass aesthetic - sleek, modern, high-tech

  -- Component styling - Sleek, modern, cyberpunk aesthetic
  component_style = {
    corner_radius = 11,     -- Very rounded, futuristic
    border_width = 0,       -- No borders, clean glass
    card_height = 26,       -- Standard height
    padding = 10,           -- Tight, modern padding
  },

  -- Base colors (original names for backwards compatibility)
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

  -- Semantic colors (NEW - for better component styling)
  accent = 0xff7aa2f7,    -- blue
  surface = 0xff24283b,   -- bg_highlight
  border = 0xff414868,    -- bg_visual
  text = 0xffc0caf5,      -- fg
  text_muted = 0xff565f89, -- comment
  success = 0xff9ece6a,   -- green
  warning = 0xffe0af68,   -- yellow
  error = 0xfff7768e,     -- red

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
