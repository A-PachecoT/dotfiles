#!/bin/bash

# TuneUp Installation Script
# Instala TuneUp en tu sistema HammerSpoon + SketchyBar

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HAMMERSPOON_DIR="$HOME/.hammerspoon"
SKETCHYBAR_PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

echo "🎵 TuneUp Installer"
echo "=================="
echo ""

# 1. Instalar módulo HammerSpoon
echo "📦 Installing HammerSpoon module..."
if [ ! -d "$HAMMERSPOON_DIR" ]; then
    echo "⚠️  HammerSpoon config directory not found at $HAMMERSPOON_DIR"
    echo "   Creating directory..."
    mkdir -p "$HAMMERSPOON_DIR"
fi

cp "$SCRIPT_DIR/hammerspoon/tuneup.lua" "$HAMMERSPOON_DIR/tuneup.lua"
echo "✅ Copied tuneup.lua to $HAMMERSPOON_DIR"

# 2. Actualizar init.lua
echo ""
echo "🔧 Updating HammerSpoon init.lua..."
INIT_LUA="$HAMMERSPOON_DIR/init.lua"

if [ -f "$INIT_LUA" ]; then
    # Verificar si ya está añadido
    if grep -q "require.*tuneup" "$INIT_LUA"; then
        echo "⚠️  TuneUp already loaded in init.lua (skipping)"
    else
        echo "" >> "$INIT_LUA"
        echo "-- TuneUp - Audio Profile Manager" >> "$INIT_LUA"
        echo "tuneup = require(\"tuneup\")" >> "$INIT_LUA"
        echo "✅ Added TuneUp to init.lua"
    fi
else
    echo "⚠️  init.lua not found, creating new one..."
    cat > "$INIT_LUA" <<'EOF'
-- HammerSpoon Configuration

-- TuneUp - Audio Profile Manager
tuneup = require("tuneup")
EOF
    echo "✅ Created init.lua with TuneUp"
fi

# 3. Instalar plugin de SketchyBar (opcional)
echo ""
read -p "📊 Install SketchyBar integration? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ ! -d "$SKETCHYBAR_PLUGIN_DIR" ]; then
        echo "⚠️  SketchyBar plugin directory not found at $SKETCHYBAR_PLUGIN_DIR"
        echo "   Creating directory..."
        mkdir -p "$SKETCHYBAR_PLUGIN_DIR"
    fi

    cp "$SCRIPT_DIR/sketchybar/tuneup.sh" "$SKETCHYBAR_PLUGIN_DIR/tuneup.sh"
    chmod +x "$SKETCHYBAR_PLUGIN_DIR/tuneup.sh"
    echo "✅ Installed SketchyBar plugin"

    echo ""
    echo "⚠️  MANUAL STEP REQUIRED:"
    echo "   Add the following to your ~/.config/sketchybar/sketchybarrc:"
    echo ""
    cat "$SCRIPT_DIR/sketchybar/tuneup_item.sh"
    echo ""
    echo "   (The configuration is also available in: $SCRIPT_DIR/sketchybar/tuneup_item.sh)"
else
    echo "⏭️  Skipped SketchyBar integration"
fi

# 4. Reload HammerSpoon
echo ""
read -p "🔄 Reload HammerSpoon now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v hs &> /dev/null; then
        hs -c "hs.reload()" 2>/dev/null && echo "✅ HammerSpoon reloaded" || echo "⚠️  Failed to reload (try manually)"
    else
        echo "⚠️  'hs' command not found. Reload HammerSpoon manually."
    fi
else
    echo "⏭️  Skipped reload (remember to reload HammerSpoon manually)"
fi

echo ""
echo "🎉 TuneUp installation complete!"
echo ""
echo "Quick Start:"
echo "  • Press Cmd+Alt+E to toggle between profiles"
echo "  • Default profiles: 🎵 Normal / 🔊 Bass Boosted"
echo "  • Settings saved to: ~/Library/Preferences/com.tuneup.settings.json"
echo ""
echo "Debug:"
echo "  • View logs: hs -c 'hs.console.show()'"
echo "  • Manual toggle: hs -c 'tuneup.toggleProfile()'"
echo "  • List profiles: hs -c 'hs.inspect(tuneup.listProfiles())'"
echo ""
echo "Documentation: $SCRIPT_DIR/README.md"
echo ""
