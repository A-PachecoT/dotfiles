#!/bin/bash

# Check if Obsidian is already running (check for electron instance running obsidian)
if pgrep -f "electron.*obsidian" > /dev/null; then
    # Get the workspace where Obsidian is running and its address
    obsidian_info=$(hyprctl clients -j | jq -r '.[] | select(.class == "obsidian") | "\(.workspace.id) \(.address)"' | head -n1)
    
    if [ -n "$obsidian_info" ]; then
        obsidian_workspace=$(echo "$obsidian_info" | cut -d' ' -f1)
        obsidian_address=$(echo "$obsidian_info" | cut -d' ' -f2)
        
        # Switch to workspace and focus the window
        hyprctl dispatch workspace "$obsidian_workspace"
        hyprctl dispatch focuswindow "address:$obsidian_address"
    else
        # If we can't find the workspace but process exists, just go to workspace 4
        hyprctl dispatch workspace 4
    fi
else
    # Launch Obsidian on workspace 4 if not running
    hyprctl dispatch workspace 4
    obsidian &
fi