-- Theme Manager
-- Handles theme loading and runtime theme switching

local ThemeManager = {
  current = nil,
  themes = {},
  initialized = false,
}

-- Load all available themes
function ThemeManager:load_themes()
  self.themes = {
    nord = require("themes.nord"),
    gruvbox = require("themes.gruvbox"),
    catppuccin = require("themes.catppuccin"),
    tokyonight = require("themes.tokyonight"),
  }
end

-- Initialize theme system with default theme
function ThemeManager:init(default_theme)
  if self.initialized then
    return self.current
  end

  self:load_themes()

  -- Set default theme (nord if not specified)
  local theme_name = default_theme or "nord"
  self:switch(theme_name)

  self.initialized = true
  return self.current
end

-- Switch to a different theme at runtime
function ThemeManager:switch(name)
  if not self.themes[name] then
    print("ERROR: Theme '" .. name .. "' not found. Available: nord, gruvbox, catppuccin, tokyonight")
    return false
  end

  self.current = self.themes[name]
  print("Theme switched to: " .. name)

  -- Trigger theme changed event (components can subscribe to this)
  -- Only trigger if sbar is available (it won't be during initial require)
  if _G.sbar and _G.sbar.trigger then
    _G.sbar.trigger("theme_changed")
  end

  return true
end

-- Get current theme
function ThemeManager:get()
  return self.current
end

-- List available themes
function ThemeManager:list()
  local names = {}
  for name, _ in pairs(self.themes) do
    table.insert(names, name)
  end
  return names
end

-- Backwards compatibility: Make ThemeManager act like the old colors table
setmetatable(ThemeManager, {
  __index = function(table, key)
    -- If accessing a color key and theme is loaded, return from current theme
    if table.current and table.current[key] then
      return table.current[key]
    end
    -- Otherwise return the method/property from ThemeManager itself
    return rawget(table, key)
  end
})

return ThemeManager
