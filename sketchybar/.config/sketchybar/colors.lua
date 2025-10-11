-- Backwards Compatibility Layer
-- This file maintains backwards compatibility with the old color system
-- while using the new ThemeManager under the hood

local theme_manager = require("themes")

-- Initialize with Nord theme (current active theme)
theme_manager:init("nord")

-- Return the theme manager
-- The metatable in themes/init.lua makes it act like the old colors table
return theme_manager
