#!/usr/bin/env bash

# Animated workspace transitions with scale and color effects
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    # Animate to active state with bounce effect
    sketchybar --animate tanh 15 \
               --set $NAME label.color=0xFFFFFFFF \
                          background.color=0xFF3d59a1 \
                          label.padding_left=12 \
                          label.padding_right=12
else
    # Animate to inactive state
    sketchybar --animate sin 10 \
               --set $NAME label.color=0xFF888888 \
                          background.color=0x33ffffff \
                          label.padding_left=10 \
                          label.padding_right=10
fi