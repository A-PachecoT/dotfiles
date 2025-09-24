#!/bin/bash
# AeroSpace Workspace Integration (Hyprland-style)

PLUGIN_DIR="$CONFIG_DIR/plugins"
source "$HOME/.config/sketchybar/themes/tokyo-night"

# Add the aerospace workspace change event
sketchybar --add event aerospace_workspace_change

# Add workspace manager that rebuilds workspace list on changes
sketchybar --add item workspace_manager left \
           --set workspace_manager drawing=off \
           script="$PLUGIN_DIR/aerospace_workspaces.sh" \
           --subscribe workspace_manager aerospace_workspace_change

# Initialize workspaces on startup
"$PLUGIN_DIR/aerospace_workspaces.sh"