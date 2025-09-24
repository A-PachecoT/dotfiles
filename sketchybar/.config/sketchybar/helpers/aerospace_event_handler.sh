#!/bin/bash

# AeroSpace Event Handler
# Handles window and workspace events for SketchyBar

get_workspace_apps() {
    local workspace=$1
    local apps_json="{"
    local first=true

    # Get app names directly using aerospace format
    local app_list=$(aerospace list-windows --workspace "$workspace" --format '%{app-name}' 2>/dev/null | sort | uniq -c)

    while read -r count app; do
        if [ -n "$app" ]; then
            if [ "$first" = false ]; then
                apps_json="${apps_json},"
            fi
            # Clean app name
            clean_app=$(echo "$app" | sed 's/"/\\"/g')
            apps_json="${apps_json}\"${clean_app}\":${count}"
            first=false
        fi
    done <<< "$app_list"

    apps_json="${apps_json}}"
    echo "$apps_json"
}

# Function to update all workspace app icons
update_all_spaces() {
    for ws in $(aerospace list-workspaces --all); do
        local apps=$(get_workspace_apps "$ws")
        # Send proper INFO structure to SketchyBar
        sketchybar --trigger space_windows_change INFO="{\"space\":${ws},\"apps\":${apps}}"
    done
}

# Function to handle workspace change
handle_workspace_change() {
    local focused=$1

    # Update space selection
    for i in {1..10}; do
        if [ "$i" = "$focused" ]; then
            sketchybar --trigger space_change SELECTED=true SID=$i
        else
            sketchybar --trigger space_change SELECTED=false SID=$i
        fi
    done

    # Update app icons
    update_all_spaces
}

# Main execution
case "${1:-update}" in
    workspace_change)
        handle_workspace_change "$2"
        ;;
    update|*)
        update_all_spaces
        ;;
esac