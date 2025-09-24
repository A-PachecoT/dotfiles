#!/bin/bash

# Media Event Provider for SketchyBar
# Monitors media playback and sends events to SketchyBar

update_media() {
  if command -v nowplaying-cli &> /dev/null; then
    # Get current media state
    STATE=$(nowplaying-cli get playbackRate 2>/dev/null)

    if [ "$STATE" = "0" ]; then
      MEDIA_STATE="paused"
    elif [ "$STATE" = "1" ]; then
      MEDIA_STATE="playing"
    else
      MEDIA_STATE="stopped"
    fi

    # Get media info
    APP=$(nowplaying-cli get app 2>/dev/null || echo "")
    TITLE=$(nowplaying-cli get title 2>/dev/null || echo "")
    ARTIST=$(nowplaying-cli get artist 2>/dev/null || echo "")
    ALBUM=$(nowplaying-cli get album 2>/dev/null || echo "")

    # Send event to SketchyBar
    sketchybar --trigger media_change \
      INFO.state="$MEDIA_STATE" \
      INFO.app="$APP" \
      INFO.title="$TITLE" \
      INFO.artist="$ARTIST" \
      INFO.album="$ALBUM"
  fi
}

# Monitor for changes (run in loop)
while true; do
  update_media
  sleep 1
done