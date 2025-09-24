local colors = require("colors")
local settings = require("settings")

-- Available themes
local themes = {
  { name = "Tokyo Night", file = "colors_tokyonight.lua" },
  { name = "Catppuccin", file = "colors_catppuccin.lua" },
  { name = "Gruvbox", file = "colors_gruvbox.lua" },
  { name = "Nord", file = "colors_nord.lua" }
}

local current_theme_index = 1

-- Create theme switcher button
local theme_switcher = sbar.add("item", "theme_switcher", {
  position = "right",
  icon = {
    string = "􀐗",  -- SF Symbol: circle.hexagongrid (subtle dots pattern)
    padding_left = 8,
    padding_right = 8,
    color = colors.grey,  -- Subtle grey color
    font = {
      family = "SF Pro",
      size = 14.0  -- Smaller size
    }
  },
  label = {
    string = "Theme",
    padding_right = 8,
    width = 0,  -- Start hidden
    color = colors.white,
    font = {
      size = 11.0
    }
  },
  background = {
    color = colors.transparent,  -- No background
    corner_radius = 6,
    height = 20,
  },
  popup = {
    background = {
      border_width = 2,
      corner_radius = 8,
      border_color = colors.white,
      color = colors.bg1,
    }
  }
})

-- Create popup menu items for each theme
for i, theme in ipairs(themes) do
  local theme_item = sbar.add("item", {
    position = "popup." .. theme_switcher.name,
    icon = {
      string = "  " .. theme.name,
      font = {
        size = 14.0
      }
    },
    label = {
      drawing = false
    },
    click_script = string.format([[
      # Switch theme
      cd ~/.config/sketchybar

      # Save current colors as backup if not default
      if [ ! -f colors_default.lua ]; then
        cp colors.lua colors_default.lua
      fi

      # Copy selected theme
      if [ -f %s ]; then
        cp %s colors.lua
        sketchybar --reload
      fi
    ]], theme.file, theme.file)
  })
end

-- Toggle popup on click
theme_switcher:subscribe("mouse.clicked", function(env)
  theme_switcher:set({ popup = { drawing = "toggle" } })
end)

-- Animate on hover
theme_switcher:subscribe("mouse.entered", function(env)
  sbar.animate("tanh", 10, function()
    theme_switcher:set({
      icon = { color = colors.white },  -- Highlight to white on hover
      label = { width = "dynamic" }
    })
  end)
end)

theme_switcher:subscribe("mouse.exited", function(env)
  sbar.animate("tanh", 10, function()
    theme_switcher:set({
      icon = { color = colors.grey },  -- Back to grey
      label = { width = 0 }
    })
  end)
end)