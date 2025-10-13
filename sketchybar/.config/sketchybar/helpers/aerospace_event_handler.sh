#!/bin/bash

# AeroSpace Event Handler
# Handles window and workspace events for SketchyBar

# Timeout for sketchybar commands (seconds)
TRIGGER_TIMEOUT=2

# Safe trigger wrapper with timeout
safe_trigger() {
    timeout "$TRIGGER_TIMEOUT" sketchybar "$@" 2>/dev/null
}

get_workspace_apps() {
    local workspace=$1
    local apps_json="{"
    local first=true

    # Get app names directly using aerospace format (with timeout)
    local app_list=$(timeout 1s aerospace list-windows --workspace "$workspace" --format '%{app-name}' 2>/dev/null | sort | uniq -c)

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
    # Batch all updates into single trigger
    local batch_data="["
    local first_ws=true

    for ws in $(timeout 2s aerospace list-workspaces --all 2>/dev/null); do
        local apps=$(get_workspace_apps "$ws")

        if [ "$first_ws" = false ]; then
            batch_data="$batch_data,"
        fi
        batch_data="$batch_data{\"space\":$ws,\"apps\":$apps}"
        first_ws=false
    done

    batch_data="$batch_data]"

    # Send single batched update
    if [ "$batch_data" != "[]" ]; then
        safe_trigger --trigger space_windows_change INFO="$batch_data"
    fi
}

# Function to handle workspace change
handle_workspace_change() {
    local focused=$1

    # Update space selection (batch into single trigger if possible)
    for i in {1..10}; do
        if [ "$i" = "$focused" ]; then
            safe_trigger --trigger space_change SELECTED=true SID=$i &
        else
            safe_trigger --trigger space_change SELECTED=false SID=$i &
        fi
    done

    # Wait for selection updates to complete
    wait

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