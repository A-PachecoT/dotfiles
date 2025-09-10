#!/usr/bin/env bash

# Clean color-only workspace indicators
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME label.color=0xffffffff  # White for active
else
    sketchybar --set $NAME label.color=0xff565f89  # Gray for inactive  
fi