-- Simple spaces configuration for debugging
local colors = require("colors")

-- Create a simple test space
for i = 1, 5 do
  sbar.add("item", "space." .. i, {
    position = "left",
    icon = {
      string = tostring(i),
      color = colors.white,
      font = { size = 14 }
    },
    label = {
      string = "App" .. i,
      color = colors.white
    },
    background = {
      color = colors.bg1,
      height = 26,
    },
    drawing = true,
    padding_left = 10,
    padding_right = 10
  })
end

print("Simple spaces loaded")