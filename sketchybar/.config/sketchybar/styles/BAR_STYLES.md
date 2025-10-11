# Bar Style Variants

The bar layout style now supports different visual variants for the background.

## Available Variants

### 1. **solid** (default)
Medium opacity background - balanced visibility and aesthetics.
```lua
local bar_style = styles.bar("solid")
sbar.bar(bar_style)
```

### 2. **transparent**
More transparent background (~63% opacity) - subtle and modern.
```lua
local bar_style = styles.bar("transparent")
sbar.bar(bar_style)
```

### 3. **minimal**
Very subtle, almost invisible (~19% opacity) - ultra minimal aesthetic.
```lua
local bar_style = styles.bar("minimal")
sbar.bar(bar_style)
```

### 4. **opaque**
Completely solid (100% opacity) - maximum visibility and contrast.
```lua
local bar_style = styles.bar("opaque")
sbar.bar(bar_style)
```

### 5. **blur**
Frosted glass effect (~38% opacity + blur) - modern macOS aesthetic.
```lua
local bar_style = styles.bar("blur")
sbar.bar(bar_style)
```

### 6. **floating**
Floating bar with shadow and margins - distinct separation from screen edge.
```lua
local bar_style = styles.bar("floating")
sbar.bar(bar_style)
```

## Usage in bar.lua

Replace your current bar configuration:

```lua
-- OLD WAY (hardcoded)
sbar.bar({
  height = 40,
  color = colors.bar.bg,
  padding_right = 2,
  padding_left = 2,
})

-- NEW WAY (using styles)
local styles = require("styles")
local bar_style = styles.bar("blur")  -- Choose your variant
sbar.bar(bar_style)
```

## Quick Testing

Try different variants by editing `bar.lua` and reloading:
```bash
# Edit bar.lua to change variant
# Then reload SketchyBar
sketchybar --reload
```

## Notes

- All variants respect your current theme colors
- Opacity is adjusted automatically while preserving theme RGB values
- The "blur" variant works best on macOS with transparency enabled
- The "floating" variant adds 10px margin and offset from screen edge
