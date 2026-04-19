#!/bin/bash
# Current Application Display

PLUGIN_DIR="$CONFIG_DIR/plugins"

# Add current app item (will be repositioned after workspaces)
sketchybar --add item current_app left \
           --set current_app icon.drawing=on \
           icon.font="sketchybar-app-font:Regular:16.0" \
           script="$PLUGIN_DIR/front_app.sh" \
           --subscribe current_app front_app_switched