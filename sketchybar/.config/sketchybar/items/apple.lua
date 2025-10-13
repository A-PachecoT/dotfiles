local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local styles = require("styles")

-- Padding item required because of bracket
sbar.add("item", { width = 5 })

-- Get theme-aware button style
local button_style = styles.button()

local apple = sbar.add("item", {
  icon = {
    font = { size = 16.0 },
    string = icons.apple,
    padding_right = 8,
    padding_left = 8,
  },
  label = { drawing = false },
  background = button_style.background,
  padding_left = button_style.padding_left,
  padding_right = button_style.padding_right,
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0"
})

-- Double border for apple using a single item bracket
sbar.add("bracket", { apple.name }, {
  background = {
    color = colors.transparent,
    height = 30,
    border_color = colors.grey,
  }
})

-- Padding item required because of bracket
sbar.add("item", { width = 7 })
