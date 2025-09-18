#!/bin/bash

# Switch to the next empty workspace on the current monitor (Hyprland-like behavior)
# Searches workspaces 1-10 for the first empty one and switches to it

current_workspace=$(aerospace list-workspaces --focused)
current_monitor=$(aerospace list-monitors --focused | head -1)

# Start from the next workspace after current
start_workspace=$((current_workspace + 1))

# Check workspaces starting from next, wrapping around
for offset in {0..9}; do
    workspace=$(( (start_workspace + offset - 1) % 10 + 1 ))

    # Check if workspace is empty (no windows) on any monitor
    if [ $(aerospace list-windows --workspace $workspace | wc -l) -eq 0 ]; then
        # Move the workspace to current monitor and switch to it
        aerospace move-workspace-to-monitor --workspace $workspace $current_monitor 2>/dev/null
        aerospace workspace $workspace
        exit 0
    fi
done

# If all workspaces have windows, go to workspace 1 on current monitor
aerospace move-workspace-to-monitor --workspace 1 $current_monitor 2>/dev/null
aerospace workspace 1