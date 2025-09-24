#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

if [ "$SENDER" = "front_app_switched" ]; then
  # Map app name to sketchybar-app-font ligature
  case "$INFO" in
    "Finder") ICON=":finder:" ;;
    "Safari") ICON=":safari:" ;;
    "Terminal") ICON=":terminal:" ;;
    "Code") ICON=":code:" ;;
    "Spotify") ICON=":spotify:" ;;
    "Discord") ICON=":discord:" ;;
    "Slack") ICON=":slack:" ;;
    "Arc") ICON=":arc:" ;;
    "WezTerm") ICON=":wezterm:" ;;
    "Warp") ICON=":warp:" ;;
    "kitty") ICON=":kitty:" ;;
    "Alacritty") ICON=":alacritty:" ;;
    *) ICON=":default:" ;;  # Default icon for unknown apps
  esac

  sketchybar --set "$NAME" icon="$ICON" \
                          icon.font="sketchybar-app-font:Regular:16.0" \
                          icon.drawing=on \
                          label="$INFO"
fi
