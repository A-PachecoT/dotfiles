#!/bin/bash

# AeroSpace Window Monitor
# Monitors window changes and sends real-time updates to SketchyBar
# Simulates yabai's space_windows_change event

CACHE_DIR="/tmp/aerospace_monitor"
mkdir -p "$CACHE_DIR"

# Debounce settings
DEBOUNCE_INTERVAL=1.0  # Minimum seconds between updates
LAST_UPDATE_FILE="$CACHE_DIR/last_update"

# Timeout for sketchybar commands (seconds)
TRIGGER_TIMEOUT=2

# Safe trigger wrapper with timeout
safe_trigger() {
    timeout "$TRIGGER_TIMEOUT" sketchybar "$@" &
    local pid=$!

    # Store PID for cleanup if needed
    echo $pid >> "$CACHE_DIR/trigger_pids"

    # Wait for completion (non-blocking)
    wait $pid 2>/dev/null
}

# Cleanup old trigger processes
cleanup_triggers() {
    if [ -f "$CACHE_DIR/trigger_pids" ]; then
        while read -r pid; do
            kill -0 $pid 2>/dev/null && kill -9 $pid 2>/dev/null
        done < "$CACHE_DIR/trigger_pids"
        rm -f "$CACHE_DIR/trigger_pids"
    fi
}

get_workspace_apps() {
    local workspace=$1
    local apps_json="{"
    local first=true

    # Get window list with app names and count (with timeout)
    local app_list=$(timeout 1s aerospace list-windows --workspace "$workspace" --format '%{app-name}' 2>/dev/null | sort | uniq -c)

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

# Check if enough time has passed since last update (debouncing)
should_update() {
    if [ ! -f "$LAST_UPDATE_FILE" ]; then
        return 0  # First run, always update
    fi

    local last_update=$(cat "$LAST_UPDATE_FILE" 2>/dev/null || echo 0)
    local current_time=$(date +%s.%N)
    local time_diff=$(echo "$current_time - $last_update" | bc 2>/dev/null || echo 999)

    # Compare with debounce interval
    if (( $(echo "$time_diff >= $DEBOUNCE_INTERVAL" | bc -l) )); then
        return 0  # Enough time passed
    fi
    return 1  # Too soon
}

update_all_workspaces() {
    # Debounce check
    if ! should_update; then
        return
    fi

    # Record update time
    date +%s.%N > "$LAST_UPDATE_FILE"

    # Batch all workspace data
    local batch_data="["
    local first_ws=true

    for ws in $(timeout 2s aerospace list-workspaces --all 2>/dev/null); do
        local apps=$(get_workspace_apps "$ws")
        local cache_file="$CACHE_DIR/workspace_$ws"
        local old_apps=""

        [ -f "$cache_file" ] && old_apps=$(cat "$cache_file")

        if [ "$apps" != "$old_apps" ]; then
            echo "$apps" > "$cache_file"

            # Add to batch
            if [ "$first_ws" = false ]; then
                batch_data="$batch_data,"
            fi
            batch_data="$batch_data{\"space\":$ws,\"apps\":$apps}"
            first_ws=false
        fi
    done

    batch_data="$batch_data]"

    # Send single batched update if there are changes
    if [ "$batch_data" != "[]" ]; then
        safe_trigger --trigger space_windows_change INFO="$batch_data"
    fi
}

# Monitor focused window changes
monitor_focused() {
    local last_focused=""
    while true; do
        local current=$(timeout 1s aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)
        if [ "$current" != "$last_focused" ]; then
            last_focused="$current"
            update_all_workspaces
        fi
        sleep 1.5  # Increased from 0.5s to reduce polling frequency
    done
}

# Cleanup on exit
trap cleanup_triggers EXIT INT TERM

# Initial update
update_all_workspaces

# Start monitoring
monitor_focused