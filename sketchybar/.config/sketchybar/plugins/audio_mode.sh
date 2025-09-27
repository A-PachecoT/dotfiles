#!/bin/bash

# Set NAME if not provided (for manual testing)
NAME=${NAME:-"audio_mode"}

# Check current audio output device
CURRENT_OUTPUT=$(hs -c "hs.audiodevice.defaultOutputDevice():name()" 2>/dev/null || echo "Unknown")

# Determine if we're in speaker mode (MacBook Pro Speakers is active)
if [[ "$CURRENT_OUTPUT" == *"MacBook Pro Speakers"* ]]; then
    # Speaker mode - show speaker icon
    sketchybar --animate tanh 12 \
               --set "$NAME" icon="󰓃" \
                            icon.color=0xff7aa2f7 \
                            icon.padding_left=0 \
                            icon.padding_right=0 \
                            background.drawing=off \
                            label.drawing=off
else
    # Headphone mode - show headphone icon
    sketchybar --animate tanh 12 \
               --set "$NAME" icon="󰋋" \
                            icon.color=0xffbb9af7 \
                            icon.padding_left=0 \
                            icon.padding_right=0 \
                            background.drawing=off \
                            label.drawing=off
fi