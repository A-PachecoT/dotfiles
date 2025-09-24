#!/bin/bash
# Clock Display

PLUGIN_DIR="$CONFIG_DIR/plugins"
source "$HOME/.config/sketchybar/icons.sh"

sketchybar --add item clock right \
           --set clock icon=$CALENDAR \
           icon.font="$FONT:Bold:14.0" \
           update_freq=30 \
           script="$PLUGIN_DIR/clock.sh"