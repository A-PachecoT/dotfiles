#!/bin/bash
# Microphone Status Indicator

PLUGIN_DIR="$CONFIG_DIR/plugins"

# Microphone status indicator with toggle
sketchybar --add event mic_toggle \
           --add item mic_status right \
           --set mic_status script="$PLUGIN_DIR/mic_status.sh" \
                update_freq=0 \
                icon.font="Hack Nerd Font:Regular:16.0" \
                click_script="hs -c 'hs.eventtap.keyStroke({\"cmd\", \"shift\"}, \"m\")'" \
                --subscribe mic_status mic_toggle

# Initialize mic status on startup
"$PLUGIN_DIR/mic_status.sh"