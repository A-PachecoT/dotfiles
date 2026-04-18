# SketchyBar Configuration

Modern, modular SketchyBar configuration with theme system and reusable styles.

## Architecture

```
sketchybar/.config/sketchybar/
├── themes/                  # Theme system (NEW)
│   ├── init.lua            # ThemeManager - runtime theme switching
│   ├── nord.lua            # Nord theme
│   ├── gruvbox.lua         # Gruvbox theme
│   ├── catppuccin.lua      # Catppuccin theme
│   └── tokyonight.lua      # Tokyo Night theme
│
├── styles/                  # Reusable component styles (NEW)
│   ├── components/
│   │   ├── card.lua        # Card style (workspaces, media)
│   │   ├── button.lua      # Button style
│   │   ├── badge.lua       # Badge style (notifications)
│   │   ├── separator.lua   # Separator style
│   │   └── icon.lua        # Icon defaults
│   └── layouts/
│       ├── bar.lua         # Bar-level styling
│       └── popup.lua       # Popup styling
│
├── controllers/             # Business logic layer (NEW - example)
│   └── media.lua           # Media player logic example
│
├── items/                   # UI components
│   ├── spaces.lua          # Workspace indicators
│   ├── media.lua           # Media player
│   ├── calendar.lua        # Date/time
│   └── ...
│
├── helpers/                 # Utility functions
├── plugins/                 # Shell-based plugins
├── colors.lua              # Backwards compatibility layer (uses themes/)
├── init.lua                # Main entry point
└── README.md               # This file
```

---

## Theme System

### Using Themes

The active theme is set in `colors.lua`:

\`\`\`lua
-- colors.lua
local theme_manager = require("themes")
theme_manager:init("nord")  -- Change this to switch default theme
return theme_manager
\`\`\`

### Available Themes

- **nord** - Nord color scheme (default)
- **gruvbox** - Gruvbox Dark
- **catppuccin** - Catppuccin Mocha
- **tokyonight** - Tokyo Night

### Runtime Theme Switching

\`\`\`lua
local colors = require("colors")

-- Switch themes at runtime
colors:switch("gruvbox")

-- List available themes
local themes = colors:list()  -- { "nord", "gruvbox", "catppuccin", "tokyonight" }

-- Get current theme
local current = colors:get()
print(current.name)  -- "gruvbox"
\`\`\`

### Creating a New Theme

1. Create `themes/mytheme.lua`:

\`\`\`lua
return {
  name = "mytheme",

  -- Base colors (for backwards compatibility)
  black = 0xff000000,
  white = 0xffffffff,
  red = 0xffff0000,
  green = 0xff00ff00,
  blue = 0xff0000ff,
  yellow = 0xffffff00,
  orange = 0xffffa500,
  magenta = 0xffff00ff,
  grey = 0xff808080,
  transparent = 0x00000000,

  -- Semantic colors (NEW - use these for better theming)
  accent = 0xff0000ff,      -- Primary accent color
  surface = 0xff1a1a1a,     -- Surface color
  border = 0xff333333,      -- Border color
  text = 0xffffffff,        -- Primary text
  text_muted = 0xff808080,  -- Muted text
  success = 0xff00ff00,     -- Success color
  warning = 0xffffff00,     -- Warning color
  error = 0xffff0000,       -- Error color

  -- Bar/popup colors
  bar = {
    bg = 0xf0000000,
    border = 0xff1a1a1a,
  },
  popup = {
    bg = 0xe0000000,
    border = 0xff333333,
  },

  -- Surface variations
  bg1 = 0xff1a1a1a,
  bg2 = 0xff333333,

  -- Alpha helper
  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
\`\`\`

2. Register in `themes/init.lua`:

\`\`\`lua
self.themes = {
  nord = require("themes.nord"),
  gruvbox = require("themes.gruvbox"),
  catppuccin = require("themes.catppuccin"),
  tokyonight = require("themes.tokyonight"),
  mytheme = require("themes.mytheme"),  -- Add here
}
\`\`\`

---

## Styles System

### Using Styles

\`\`\`lua
local styles = require("styles")

-- Use default card style
local workspace = sbar.add("space", "workspace.1", styles.card())

-- Use elevated card variant
local workspace = sbar.add("space", "workspace.1", styles.card("elevated"))

-- Use primary button style
local button = sbar.add("item", "button", styles.button("primary"))

-- Merge styles
local custom = styles.merge(styles.card(), {
  background = { height = 32 }
})
\`\`\`

### Available Styles

#### Component Styles

- **card(variant)** - For workspaces, media players
  - Variants: `nil`, `"elevated"`, `"flat"`, `"highlighted"`

- **button(variant)** - For clickable items
  - Variants: `nil`, `"primary"`, `"ghost"`, `"outline"`

- **badge(variant)** - For notifications, counters
  - Variants: `nil`, `"success"`, `"warning"`, `"error"`, `"muted"`

- **separator(variant)** - Visual separators
  - Variants: `nil`, `"bold"`, `"dotted"`, `"space"`

- **icon(variant)** - Icon defaults
  - Variants: `nil`, `"large"`, `"small"`, `"muted"`, `"accent"`

#### Layout Styles

- **bar()** - Top-level bar styling
- **popup()** - Popup menu styling

### Creating Custom Styles

1. Create `styles/components/mycomponent.lua`:

\`\`\`lua
return function(variant)
  local colors = require("colors")
  local theme = colors:get()

  local base = {
    background = {
      color = theme.surface,
      border_color = theme.border,
    },
    icon = {
      color = theme.text,
    },
  }

  -- Add variant support
  if variant == "highlighted" then
    base.background.color = theme.accent
  end

  return base
end
\`\`\`

2. Register in `styles/init.lua`:

\`\`\`lua
local styles = {
  card = require("styles.components.card"),
  button = require("styles.components.button"),
  mycomponent = require("styles.components.mycomponent"),  -- Add here
}
\`\`\`

---

## Controllers (Optional)

Controllers separate business logic from UI components.

### Example: Media Controller

\`\`\`lua
-- controllers/media.lua
local MediaController = {
  whitelist = { ["Spotify"] = true, ["Music"] = true }
}

function MediaController.is_supported(app)
  return MediaController.whitelist[app] == true
end

function MediaController.on_playback_changed(event)
  if not MediaController.is_supported(event.app) then
    return nil
  end

  return {
    is_playing = (event.state == "playing"),
    artist = event.artist or "Unknown",
    title = event.title or "Unknown",
  }
end

return MediaController
\`\`\`

### Using Controllers in Components

\`\`\`lua
-- items/media.lua
local controller = require("controllers.media")

media_cover:subscribe("playback_changed", function(env)
  local data = controller.on_playback_changed(env.INFO)

  if not data then return end

  -- Update UI with controller data
  media_title:set({ label = data.title })
  media_artist:set({ label = data.artist })
end)
\`\`\`

---

## Migration Guide

### From Old to New Architecture

**Old way (hardcoded colors):**
\`\`\`lua
local colors = require("colors")

sbar.add("item", "myitem", {
  background = {
    color = colors.bg1,
    border_color = colors.grey,
  }
})
\`\`\`

**New way (semantic + theme-aware):**
\`\`\`lua
local colors = require("colors")
local styles = require("styles")

-- Option 1: Use styles
sbar.add("item", "myitem", styles.card())

-- Option 2: Use semantic colors
sbar.add("item", "myitem", {
  background = {
    color = colors.surface,      -- Semantic, not hardcoded!
    border_color = colors.border,
  }
})

-- Option 3: Mix both
local custom = styles.merge(styles.card(), {
  icon = { color = colors.accent }
})
sbar.add("item", "myitem", custom)
\`\`\`

---

## Benefits

### ✅ Completed

- **Runtime theme switching** - Change themes without reloading SketchyBar
- **Semantic colors** - `accent`, `surface`, `border` instead of `blue`, `bg1`, `grey`
- **Reusable styles** - DRY component styling
- **Backwards compatible** - Existing components still work
- **Future-proof** - Easy to add new themes and styles

### 🔮 Future Work

- Refactor components to use styles system
- Add more themes
- Create component library with styles
- Add animation helpers
- Theme preview/switcher UI

---

## Examples

### Complete Component with New Architecture

\`\`\`lua
local colors = require("colors")
local styles = require("styles")
local controller = require("controllers.mycontroller")

-- Create component with style
local my_item = sbar.add("item", "my_item", styles.card("elevated"))

-- Handle events with controller
my_item:subscribe("my_event", function(env)
  local data = controller.process(env.INFO)
  if data then
    my_item:set({ label = data.text })
  end
end)

-- Switch theme at runtime
colors:switch("gruvbox")  -- Component colors update automatically!
\`\`\`

---

## Troubleshooting

### Theme not loading

Ensure colors.lua initializes the theme:
\`\`\`lua
-- colors.lua
local theme_manager = require("themes")
theme_manager:init("nord")  -- Make sure this runs
return theme_manager
\`\`\`

### Styles not applying

Check that you're calling the style function:
\`\`\`lua
-- Wrong
sbar.add("item", "x", styles.card)

-- Correct
sbar.add("item", "x", styles.card())
\`\`\`

### Colors not updating after theme switch

Make sure you're using semantic colors or styles, not hardcoded colors:
\`\`\`lua
-- Won't update on theme switch
color = 0xff81a1c1

-- Will update on theme switch
color = colors.accent
\`\`\`

---

## Credits

Architecture refactored on 2025-10-11 with Claude Code.
Original configuration by styreep.
