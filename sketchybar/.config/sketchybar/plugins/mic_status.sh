#!/bin/bash

# Check if microphone is muted using HammerSpoon
# Since HammerSpoon manages the mute state, we'll query it directly
MUTE_STATUS=$(hs -c "hs.audiodevice.defaultInputDevice():inputMuted()" 2>/dev/null || echo "false")

if [[ "$MUTE_STATUS" == "true" ]]; then
    # Microphone is muted
    sketchybar --set $NAME icon="󰍭" \
                          icon.color=0xffe06c75 \
                          label="" \
                          background.color=0x44e06c75 \
                          background.drawing=on
else
    # Microphone is active
    sketchybar --set $NAME icon="󰍬" \
                          icon.color=0xff73daca \
                          label="" \
                          background.drawing=off
fi