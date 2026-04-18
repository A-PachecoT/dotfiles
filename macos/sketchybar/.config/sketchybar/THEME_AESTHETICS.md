# Theme Aesthetics Guide

Each theme now has its own unique **bar AND component** aesthetics that match its personality!

## 🎨 Theme Visual Styles

### 1. **Gruvbox** - Cardboard/Cork Board
**Bar Style**: `opaque`
- **Personality**: Warm, earthy, analog, retro terminal
- **Visual**: Solid and substantial (90-100% opacity)
- **Feel**: Like a cork board or cardboard - grounded, physical, warm
- **Best for**: Traditional terminal lovers, warm color preference

### 2. **Nord** - Frosted Ice
**Bar Style**: `transparent`
- **Personality**: Cool, clean, Scandinavian, minimalist
- **Visual**: Semi-transparent (~63% opacity)
- **Feel**: Like frosted glass or ice - precise, minimal, elegant
- **Best for**: Minimalists, cool color preference, distraction-free

### 3. **Catppuccin** - Cozy Café
**Bar Style**: `floating`
- **Personality**: Warm, pastel, comfortable, inviting
- **Visual**: Floating with shadows, slightly elevated
- **Feel**: Like a cozy café counter - welcoming, soft, comfortable
- **Best for**: Pastel lovers, comfortable long sessions

### 4. **Tokyo Night** - Cyberpunk Glass
**Bar Style**: `blur`
- **Personality**: Modern, sleek, high-tech, neon
- **Visual**: Frosted glass with blur effect (~38% opacity)
- **Feel**: Like neon-lit glass in a cyberpunk city - futuristic, sleek
- **Best for**: Modern aesthetic lovers, macOS natives

## 🔄 How to Switch Themes

Just edit `colors.lua` to return the theme you want:

### Current (Gruvbox):
```lua
-- colors.lua
return require("themes.gruvbox")
```

### Switch to Nord:
```lua
-- colors.lua
return require("themes.nord")
```

### Switch to Catppuccin:
```lua
-- colors.lua
return require("themes.catppuccin")
```

### Switch to Tokyo Night:
```lua
-- colors.lua
return require("themes.tokyonight")
```

Then reload:
```bash
sketchybar --reload
```

## 🎯 What Changes?

When you switch themes, **both** colors AND bar aesthetic change automatically:
- ✅ All component colors update
- ✅ Bar background style changes
- ✅ Bar opacity/blur/floating changes
- ✅ Overall visual personality transforms

## 📝 Technical Details

Each theme file (`themes/*.lua`) includes a `bar_style` property:

```lua
-- themes/gruvbox.lua
return {
  name = "gruvbox",
  bar_style = "opaque",  -- This determines the bar aesthetic
  -- ... colors
}
```

The `bar.lua` automatically reads this and applies the matching style!

## 🎨 Visual Comparison

| Theme | Bar Style | Opacity | Blur | Floating | Vibe |
|-------|-----------|---------|------|----------|------|
| **Gruvbox** | opaque | 100% | ❌ | ❌ | Solid, warm cardboard |
| **Nord** | transparent | ~63% | ❌ | ❌ | Frosted ice, minimal |
| **Catppuccin** | floating | Medium | ❌ | ✅ | Elevated, cozy café |
| **Tokyo Night** | blur | ~38% | ✅ | ❌ | Sleek cyberpunk glass |

## 🎨 Component Styling Per Theme

Each theme now also customizes component appearance (cards, buttons, badges):

### **Gruvbox** - Bold Cardboard Components
- **Corner Radius**: 2px (sharp, slightly softened)
- **Border Width**: 2px (thick, substantial borders)
- **Card Height**: 28px (taller, more presence)
- **Padding**: 12px (generous spacing)
- **Feel**: Analog, bold, like cardboard cutouts

### **Nord** - Minimal Frosted Components
- **Corner Radius**: 4px (subtle rounds, clean edges)
- **Border Width**: 1px (thin, minimal borders)
- **Card Height**: 26px (standard)
- **Padding**: 10px (tight, precise spacing)
- **Feel**: Clean, minimal, frosted glass precision

### **Catppuccin** - Cozy Rounded Components
- **Corner Radius**: 8px (rounded, inviting)
- **Border Width**: 1px (medium borders)
- **Card Height**: 26px (standard)
- **Padding**: 12px (comfortable spacing)
- **Feel**: Soft, warm, cozy café vibes

### **Tokyo Night** - Sleek Cyberpunk Components
- **Corner Radius**: 11px (very rounded, futuristic)
- **Border Width**: 0px (no borders, clean glass)
- **Card Height**: 26px (standard)
- **Padding**: 10px (tight, modern spacing)
- **Feel**: Sleek, modern, high-tech neon glass

## 📊 Visual Comparison Table

| Theme | Bar Style | Bar Corner | Bar Border | Component Corner | Component Border | Feel |
|-------|-----------|------------|------------|------------------|------------------|------|
| **Gruvbox** | opaque | 0 | 0 | **2px** | **2px** | Bold cardboard |
| **Nord** | transparent | 0 | 0 | **4px** | **1px** | Frosted minimal |
| **Catppuccin** | floating | **9px** | **2px** | **8px** | **1px** | Cozy café card |
| **Tokyo Night** | blur | 0 | 0 | **11px** | **0px** | Sleek cyberpunk |

## 🔧 Technical Details

Each theme includes a `component_style` property:

```lua
-- themes/gruvbox.lua
component_style = {
  corner_radius = 2,      -- Sharp corners
  border_width = 2,       -- Thick borders
  card_height = 28,       -- Taller cards
  padding = 12,           -- Generous spacing
}
```

All component styles (card, button, badge, separator, icon) automatically read these values!

## 💡 Pro Tips

**Override bar style** by editing `bar.lua`:
```lua
local bar_style = styles.bar("minimal")  -- Override theme preference
```

**Override component style** by editing component files or theme directly:
```lua
-- In your theme file
component_style = {
  corner_radius = 15,  -- Custom value
  -- ...
}
```

But by default, let each theme express its unique personality! 🎨
