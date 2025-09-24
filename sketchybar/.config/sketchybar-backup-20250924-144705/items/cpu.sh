#!/bin/bash
# CPU Usage Monitor

PLUGIN_DIR="$CONFIG_DIR/plugins"
source "$HOME/.config/sketchybar/themes/tokyo-night"
source "$HOME/.config/sketchybar/icons.sh"

sketchybar --add item cpu right \
           --set cpu icon=$CPU \
                icon.font="$FONT:Bold:14.0" \
                icon.color=$BLUE \
                update_freq=2 \
                script="$PLUGIN_DIR/cpu.sh"