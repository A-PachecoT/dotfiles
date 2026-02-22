local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

sbar.exec("killall ram_load >/dev/null; $CONFIG_DIR/helpers/event_providers/ram_load/bin/ram_load ram_update 5.0")

local ram = sbar.add("graph", "widgets.ram", 42, {
  position = "right",
  graph = { color = colors.blue },
  background = {
    height = 22,
    color = { alpha = 0 },
    border_color = { alpha = 0 },
    drawing = true,
  },
  icon = { string = icons.ram },
  label = {
    string = "ram ??%",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    align = "right",
    padding_right = 0,
    width = 0,
    y_offset = 4,
  },
  padding_right = settings.paddings + 6,
  popup = { align = "center" },
})

local swap_label = sbar.add("item", "widgets.ram.swap", {
  position = "popup." .. ram.name,
  icon = { drawing = false },
  label = {
    string = "swap: ...",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 12.0,
    },
    color = colors.white,
  },
  background = { color = colors.bg1, height = 26 },
  width = 160,
})

ram:subscribe("ram_update", function(env)
  local load = tonumber(env.used_percent)
  ram:push({ load / 100. })

  local color = colors.blue
  if load > 50 then
    if load < 70 then
      color = colors.yellow
    elseif load < 85 then
      color = colors.orange
    else
      color = colors.red
    end
  end

  ram:set({
    graph = { color = color },
    label = "ram " .. env.used_percent .. "%",
  })

  local swap = tonumber(env.swap_used) or 0
  local swap_text
  if swap > 1024 then
    swap_text = string.format("swap: %.1f GB / %d GB", swap / 1024, tonumber(env.swap_total) / 1024)
  elseif swap > 0 then
    swap_text = string.format("swap: %d MB / %d GB", swap, tonumber(env.swap_total) / 1024)
  else
    swap_text = "swap: none"
  end
  swap_label:set({ label = swap_text })
end)

ram:subscribe("mouse.entered", function(env)
  ram:set({ popup = { drawing = true } })
end)

ram:subscribe("mouse.exited.global", function(env)
  ram:set({ popup = { drawing = false } })
end)

ram:subscribe("mouse.clicked", function(env)
  sbar.exec("open -a 'Activity Monitor'")
end)

sbar.add("bracket", "widgets.ram.bracket", { ram.name }, {
  background = { color = colors.bg1 },
})

sbar.add("item", "widgets.ram.padding", {
  position = "right",
  width = settings.group_paddings,
})
