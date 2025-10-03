#!/usr/bin/env bash

# clipboard-restart.sh - Restart clipboard services when they stop working

# Kill any existing clipboard processes
pkill -f "wl-paste.*watch" || true
pkill -f "clipsync" || true
pkill -f "clipse.*listen" || true

# Wait a moment to ensure processes are terminated
sleep 2

# Run the bridge to sync existing cliphist entries to clipse
if [ -f "$HOME/.config/hypr/scripts/clipse-cliphist-bridge.sh" ]; then
    "$HOME/.config/hypr/scripts/clipse-cliphist-bridge.sh"
fi

# Restart clipboard services
if [ -f "$HOME/.config/hypr/scripts/autostart-clipboard.sh" ]; then
    "$HOME/.config/hypr/scripts/autostart-clipboard.sh"
    notify-send -a "Clipboard" "Clipboard services restarted" -t 3000
else
    # Fallback if autostart script doesn't exist
    # Start clipse listener first
    if command -v clipse >/dev/null 2>&1; then
        clipse -listen &
        sleep 1
    fi
    
    # Start clipboard history for backward compatibility
    wl-paste --type text --watch sh -c 'cliphist store' &
    wl-paste --type image --watch sh -c 'cliphist store' &
    
    # Start clipboard sync if available
    if [ -f "$HOME/.config/hypr/scripts/clipsync.sh" ]; then
        "$HOME/.config/hypr/scripts/clipsync.sh" watch without-notifications &
    fi
    
    notify-send -a "Clipboard" "Clipboard services restarted (fallback mode)" -t 3000
fi

exit 0 