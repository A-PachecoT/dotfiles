#!/bin/bash

# Check if microphone is muted using HammerSpoon
# Since HammerSpoon manages the mute state, we'll query it directly
MUTE_STATUS=$(hs -c "hs.audiodevice.defaultInputDevice():inputMuted()" 2>/dev/null || echo "false")

if [[ "$MUTE_STATUS" == "true" ]]; then
    # Microphone is muted - animate transition
    sketchybar --animate tanh 12 \
               --set $NAME icon="󰍭" \
                          icon.color=0xffe06c75 \
                          icon.padding_right=0 \
                          label="" \
                          padding_right=0 \
                          background.color=0x44e06c75 \
                          background.drawing=on \
                          background.padding_left=0 \
                          background.padding_right=0
else
    # Microphone is active - animate transition
    sketchybar --animate tanh 12 \
               --set $NAME icon="󰍬" \
                          icon.color=0xff73daca \
                          icon.padding_right=0 \
                          label="" \
                          padding_right=0 \
                          background.drawing=off
fi