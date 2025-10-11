# Theme Aesthetics Guide

Each theme now has its own unique bar aesthetic that matches its personality!

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

## 💡 Pro Tip

You can override a theme's default bar style by editing `bar.lua`:

```lua
-- Force a specific style regardless of theme
local bar_style = styles.bar("minimal")  -- Override theme preference
sbar.bar(bar_style)
```

But by default, let each theme use its personality! 🎨
