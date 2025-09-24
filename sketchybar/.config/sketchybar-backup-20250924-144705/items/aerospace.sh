#!/bin/bash

# AeroSpace Workspaces for SketchyBar
# Based on mplusp/dotfiles approach

source "$HOME/.config/sketchybar/themes/tokyo-night"

# Create workspace bracket
sketchybar --add bracket workspaces '/workspace\..*/'

# Add workspaces 1-10
for i in {1..10}; do
  sketchybar --add item workspace.$i left \
             --set workspace.$i \
                   icon="$i" \
                   icon.font="MonoLisa:Bold:14.0" \
                   icon.color=$WHITE \
                   icon.padding_left=8 \
                   icon.padding_right=8 \
                   background.color=$TRANSPARENT \
                   background.corner_radius=6 \
                   background.height=24 \
                   label.drawing=off \
                   script="$PLUGIN_DIR/aerospace.sh" \
                   click_script="aerospace workspace $i"
done

# Style the bracket
sketchybar --set workspaces \
                 background.color=$BAR_COLOR \
                 background.corner_radius=8 \
                 background.height=28

# Subscribe to aerospace workspace changes
sketchybar --subscribe workspaces aerospace_workspace_change