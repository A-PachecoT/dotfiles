#!/bin/bash
# Microphone Status Indicator

# Microphone status indicator with toggle
sketchybar --add event mic_toggle \
           --add item mic_status right \
           --set mic_status script="$CONFIG_DIR/plugins/mic_status.sh" \
                update_freq=0 \
                icon.font="Hack Nerd Font:Regular:16.0" \
                icon.color=0xffa6e3a1 \
                icon="󰍬" \
                background.drawing=off \
                background.color=0x33f38ba8 \
                background.padding_left=4 \
                background.padding_right=4 \
                background.corner_radius=4 \
                padding_right=8 \
                click_script="hs -c 'hs.eventtap.keyStroke({\"cmd\", \"shift\"}, \"m\")' && sleep 0.2 && sketchybar --trigger mic_toggle" \
                --subscribe mic_status mic_toggle

# Initialize mic status on startup
sketchybar --trigger mic_toggle