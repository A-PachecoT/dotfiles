#!/bin/bash

source "$HOME/.config/sketchybar/themes/tokyo-night"
source "$HOME/.config/sketchybar/icons.sh"

# Check if Spotify is running
if ! pgrep -x "Spotify" > /dev/null; then
  sketchybar --set spotify drawing=off
  exit 0
fi

# Get track info using osascript
STATE=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null || echo "stopped")

if [ "$STATE" = "playing" ]; then
  TRACK=$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null || echo "Unknown")
  ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track as string' 2>/dev/null || echo "Unknown")

  # Truncate if too long
  if [ ${#TRACK} -gt 25 ]; then
    TRACK=$(echo "$TRACK" | cut -c1-22)...
  fi

  if [ ${#ARTIST} -gt 20 ]; then
    ARTIST=$(echo "$ARTIST" | cut -c1-17)...
  fi

  sketchybar --set spotify drawing=on \
                          label="$TRACK - $ARTIST" \
                          label.drawing=on \
                          icon=$SPOTIFY_PLAY_PAUSE
elif [ "$STATE" = "paused" ]; then
  sketchybar --set spotify drawing=on \
                          label="Paused" \
                          label.drawing=on \
                          icon=$SPOTIFY_PLAY_PAUSE
else
  sketchybar --set spotify drawing=off
fi