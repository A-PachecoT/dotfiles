local styles = require("styles")
local colors = require("colors")

-- Get the current theme (handle both ThemeManager and direct theme)
-- Each theme has its own aesthetic:
-- - Gruvbox: "opaque" (cardboard/cork board - warm, solid)
-- - Nord: "transparent" (frosted ice - cool, minimal)
-- - Catppuccin: "floating" (cozy café - warm, elevated)
-- - Tokyo Night: "blur" (cyberpunk glass - sleek, modern)
local theme = colors.get and colors:get() or colors
local preferred_style = theme.bar_style or "solid"

local bar_style = styles.bar(preferred_style)

-- Apply the style to the bar
sbar.bar(bar_style)
