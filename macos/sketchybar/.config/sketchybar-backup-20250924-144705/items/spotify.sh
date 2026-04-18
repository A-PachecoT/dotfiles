#!/bin/bash
# Spotify Integration

PLUGIN_DIR="$CONFIG_DIR/plugins"
source "$HOME/.config/sketchybar/themes/tokyo-night"
source "$HOME/.config/sketchybar/icons.sh"

# Spotify integration enabled
sketchybar --add item spotify center \
           --set spotify icon=$SPOTIFY_PLAY_PAUSE \
                icon.font="$FONT:Bold:16.0" \
                icon.color=$GREEN \
                label.drawing=off \
                label.padding_left=6 \
                label.padding_right=6 \
                background.color=0x33ffffff \
                background.corner_radius=8 \
                background.height=22 \
                script="$PLUGIN_DIR/spotify.sh" \
                update_freq=1 \
                click_script="open -a Spotify"