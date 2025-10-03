#!/usr/bin/env bash

# Clipboard selector using wofi (native Wayland)
selection=$(cliphist list | wofi --dmenu -p "📋 Clipboard:" --lines 10)

if [ -n "$selection" ]; then
    echo "$selection" | cliphist decode | wl-copy
fi