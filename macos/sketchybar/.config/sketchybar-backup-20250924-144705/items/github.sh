#!/bin/bash
# GitHub Notifications

PLUGIN_DIR="$CONFIG_DIR/plugins"
source "$HOME/.config/sketchybar/themes/tokyo-night"
source "$HOME/.config/sketchybar/icons.sh"

sketchybar --add item github.bell right \
           --set github.bell icon=$BELL \
                icon.font="$FONT:Bold:16.0" \
                icon.color=$BLUE \
                label.drawing=off \
                update_freq=180 \
                script="$PLUGIN_DIR/github.sh" \
                click_script="open https://github.com/notifications"