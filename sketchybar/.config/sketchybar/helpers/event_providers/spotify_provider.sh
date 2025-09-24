#!/bin/bash

# Spotify Event Provider for SketchyBar using AppleScript

update_spotify() {
  # Check if Spotify is running
  if pgrep -x "Spotify" > /dev/null; then
    # Get Spotify state using AppleScript
    STATE=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null || echo "stopped")

    if [ "$STATE" = "playing" ] || [ "$STATE" = "paused" ]; then
      TRACK=$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null)
      ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track as string' 2>/dev/null)
      ALBUM=$(osascript -e 'tell application "Spotify" to album of current track as string' 2>/dev/null)

      # Send event to SketchyBar
      sketchybar --trigger media_change \
        INFO.state="$STATE" \
        INFO.app="Spotify" \
        INFO.title="$TRACK" \
        INFO.artist="$ARTIST" \
        INFO.album="$ALBUM"
    else
      sketchybar --trigger media_change INFO.state="stopped" INFO.app="Spotify"
    fi
  fi
}

# Monitor for changes
while true; do
  update_spotify
  sleep 1
done