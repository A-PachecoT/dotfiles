#!/bin/bash

# Get the current application name
APP_NAME="$1"

# Use the app name directly as the icon (sketchybar-app-font uses ligatures)
# The font will automatically convert known app names to their icons
sketchybar --set current_app icon="$APP_NAME" \
                             icon.font="sketchybar-app-font:Regular:16.0" \
                             label="$APP_NAME" \
                             label.font="$FONT:Regular:12.0"