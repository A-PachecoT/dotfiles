#!/bin/bash

# AeroSpace Window Monitor
# Monitors window changes and sends real-time updates to SketchyBar
# Simulates yabai's space_windows_change event

CACHE_DIR="/tmp/aerospace_monitor"
mkdir -p "$CACHE_DIR"

get_workspace_apps() {
    local workspace=$1
    local apps_json="{"
    local first=true

    # Get window list with app names and count
    local app_list=$(aerospace list-windows --workspace "$workspace" --format '%{app-name}' 2>/dev/null | sort | uniq -c)

    while read -r count app; do
        if [ -n "$app" ]; then
            if [ "$first" = false ]; then
                apps_json="$apps_json,"
            fi
            # Clean app name and add count
            clean_app=$(echo "$app" | sed 's/"/\\"/g')
            apps_json="$apps_json\"$clean_app\":$count"
            first=false
        fi
    done <<< "$app_list"

    apps_json="$apps_json}"
    echo "$apps_json"
}

update_all_workspaces() {
    for ws in $(aerospace list-workspaces --all); do
        local apps=$(get_workspace_apps "$ws")
        local cache_file="$CACHE_DIR/workspace_$ws"
        local old_apps=""

        [ -f "$cache_file" ] && old_apps=$(cat "$cache_file")

        if [ "$apps" != "$old_apps" ]; then
            echo "$apps" > "$cache_file"
            # Send update to SketchyBar with proper INFO structure
            sketchybar --trigger space_windows_change INFO="{\"space\":$ws,\"apps\":$apps}"
        fi
    done
}

# Monitor focused window changes
monitor_focused() {
    local last_focused=""
    while true; do
        local current=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)
        if [ "$current" != "$last_focused" ]; then
            last_focused="$current"
            update_all_workspaces
        fi
        sleep 0.5
    done
}

# Initial update
update_all_workspaces

# Start monitoring
monitor_focused