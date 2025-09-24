#!/bin/bash

# AeroSpace integration for SketchyBar spaces
# This script updates workspace selection and app icons

# Get current workspace
FOCUSED=$(aerospace list-workspaces --focused)

# Update selection status for all workspaces
for i in {1..10}; do
    if [ "$i" = "$FOCUSED" ]; then
        sketchybar --trigger space_change SELECTED=true SID=$i
    else
        sketchybar --trigger space_change SELECTED=false SID=$i
    fi
done

# Update app icons for each workspace
for ws in $(aerospace list-workspaces --all); do
    # Get apps in workspace
    apps_json="{"
    first=true

    # Get all apps in the workspace
    apps=$(aerospace list-windows --workspace "$ws" --format '%{app-name}' 2>/dev/null | sort -u)

    if [ -n "$apps" ]; then
        while IFS= read -r app; do
            if [ -n "$app" ]; then
                if [ "$first" = false ]; then
                    apps_json="$apps_json,"
                fi
                # Clean app name and add to JSON
                clean_app=$(echo "$app" | sed 's/"/\\"/g')
                apps_json="$apps_json\"$clean_app\":1"
                first=false
            fi
        done <<< "$apps"
    fi

    apps_json="$apps_json}"

    # Debug output
    echo "Workspace $ws: apps=$apps_json" >&2

    # Trigger the update - the Lua expects INFO.space and INFO.apps
    sketchybar --trigger space_windows_change INFO.space="$ws" INFO.apps="$apps_json"
done