#!/bin/bash

# Set NAME if not provided (for manual testing)
NAME=${NAME:-"mic_status"}

# Check if microphone is muted using HammerSpoon (with fallback)
# Use perl timeout wrapper to prevent hanging
MUTE_STATUS=$(perl -e 'alarm 1; exec @ARGV' hs -c "hs.audiodevice.defaultInputDevice():inputMuted()" 2>/dev/null || echo "false")

if [[ "$MUTE_STATUS" == "true" ]]; then
    # Microphone is muted - red with background
    sketchybar --animate tanh 12 \
               --set "$NAME" icon="󰍭" \
                            icon.color=0xfff38ba8 \
                            icon.padding_left=2 \
                            icon.padding_right=1 \
                            background.color=0x33f38ba8 \
                            background.drawing=on \
                            background.padding_left=0 \
                            background.padding_right=0
else
    # Microphone is active - green without background
    sketchybar --animate tanh 12 \
               --set "$NAME" icon="󰍬" \
                            icon.color=0xffa6e3a1 \
                            icon.padding_left=2 \
                            icon.padding_right=2 \
                            background.drawing=off
fi