#!/bin/bash

NAME=${NAME:-"audio_mode"}

# Handle different events
if [[ "$SENDER" == "mouse.entered" ]]; then
    # Show the label on hover with smooth animation
    sketchybar --animate tanh 20 \
               --set "$NAME" label.width=dynamic \
                            label.padding_left=6 \
                            icon.padding_right=2
elif [[ "$SENDER" == "mouse.exited" ]]; then
    # Hide the label when mouse leaves with smooth animation
    sketchybar --animate tanh 20 \
               --set "$NAME" label.width=0 \
                            label.padding_left=0 \
                            icon.padding_right=0
elif [[ "$SENDER" == "audio_mode_change" ]] || [[ "$SENDER" == "forced" ]]; then
    # Update the audio mode status
    # Check current audio output device
    CURRENT_OUTPUT=$(hs -c "hs.audiodevice.defaultOutputDevice():name()" 2>/dev/null || echo "Unknown")

    # Truncate device name if too long
    DISPLAY_NAME="$CURRENT_OUTPUT"
    if [[ "$CURRENT_OUTPUT" == "MacBook Pro Speakers" ]]; then
        DISPLAY_NAME="Built-in Speakers"
    elif [[ "$CURRENT_OUTPUT" == *"WH-1000XM4"* ]]; then
        DISPLAY_NAME="Sony WH-1000XM4"
    elif [[ "$CURRENT_OUTPUT" == *"fifine"* ]]; then
        DISPLAY_NAME="Fifine Speaker"
    elif [[ "$CURRENT_OUTPUT" == *"Echo Dot"* ]]; then
        DISPLAY_NAME="Echo Dot"
    fi

    # Use AUDIO_MODE from HammerSpoon (passed as env var)
    if [[ "$AUDIO_MODE" == "SPEAKER" ]]; then
        # Speaker mode - show speaker icon
        sketchybar --animate circ 12 \
                   --set "$NAME" icon="󰓃" \
                                icon.color=0xff7aa2f7 \
                                label="$DISPLAY_NAME"
    else
        # Headphone mode - show headphone icon
        sketchybar --animate circ 12 \
                   --set "$NAME" icon="󰋋" \
                                icon.color=0xffbb9af7 \
                                label="$DISPLAY_NAME"
    fi
fi