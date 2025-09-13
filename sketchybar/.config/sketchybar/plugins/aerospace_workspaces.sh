#!/usr/bin/env bash

# Optimized workspace management - only rebuild when workspace list changes
# Just update colors for workspace changes, full rebuild only when needed

source "$HOME/.config/sketchybar/themes/tokyo-night"

# Get current workspace state
MONITOR1_WS=$(aerospace list-workspaces --monitor 1 --empty no | sort -nu)
MONITOR2_WS=$(aerospace list-workspaces --monitor 2 --empty no | sort -nu)
FOCUSED_WS=$(aerospace list-workspaces --focused)
FOCUSED_MONITOR=$(aerospace list-monitors --focused | cut -d' ' -f1)

# Add focused workspace to appropriate monitor if not already included
if [ "$FOCUSED_MONITOR" = "1" ]; then
    if ! echo "$MONITOR1_WS" | grep -q "^$FOCUSED_WS$"; then
        MONITOR1_WS=$(echo -e "$MONITOR1_WS\n$FOCUSED_WS" | sort -nu)
    fi
else
    if ! echo "$MONITOR2_WS" | grep -q "^$FOCUSED_WS$"; then
        MONITOR2_WS=$(echo -e "$MONITOR2_WS\n$FOCUSED_WS" | sort -nu)
    fi
fi

ALL_WORKSPACES="$MONITOR1_WS $MONITOR2_WS"

# Ensure we always have at least the focused workspace visible
if [ -z "$ALL_WORKSPACES" ] || [ "$ALL_WORKSPACES" = " " ]; then
    echo "Warning: No workspaces found, adding focused workspace"
    if [ "$FOCUSED_MONITOR" = "1" ]; then
        MONITOR1_WS="$FOCUSED_WS"
    else
        MONITOR2_WS="$FOCUSED_WS"
    fi
    ALL_WORKSPACES="$MONITOR1_WS $MONITOR2_WS"
fi

# Check if we need a full rebuild (workspace list changed)
CACHE_FILE="/tmp/sketchybar_workspaces"
CURRENT_STATE="$MONITOR1_WS|$MONITOR2_WS"

# Force rebuild if no workspaces are visible or if state changed
EXISTING_SPACES=$(sketchybar --query | grep '"name": "space\.' | wc -l)
if [ ! -f "$CACHE_FILE" ] || [ "$(cat "$CACHE_FILE" 2>/dev/null)" != "$CURRENT_STATE" ] || [ "$EXISTING_SPACES" -eq 0 ]; then
    # Full rebuild needed
    echo "$CURRENT_STATE" > "$CACHE_FILE"
    
    # Remove all existing workspace items and separators
    sketchybar --remove '/space\..*/' 2>/dev/null
    sketchybar --remove monitor_separator 2>/dev/null
    sketchybar --remove spacer 2>/dev/null

    # Create workspace items for Monitor 1
    for sid in $MONITOR1_WS; do
        sketchybar --add item space.$sid left \
            --subscribe space.$sid aerospace_workspace_change \
            --set space.$sid \
            icon.drawing=off \
            label="$sid" \
            label.font="MonoLisa Nerd Font:Regular:14.0" \
            label.color=$WORKSPACE_INACTIVE \
            label.padding_left=8 \
            label.padding_right=8 \
            click_script="aerospace workspace $sid" \
            script="$HOME/.config/sketchybar/plugins/aerospace.sh $sid"
    done

    # Add monitor separator if both monitors have workspaces
    if [ -n "$MONITOR1_WS" ] && [ -n "$MONITOR2_WS" ]; then
        sketchybar --add item monitor_separator left \
                   --set monitor_separator icon="|" icon.color=$GREY icon.font="Hack Nerd Font:Regular:14.0" label.drawing=off
    fi

    # Create workspace items for Monitor 2
    for sid in $MONITOR2_WS; do
        sketchybar --add item space.$sid left \
            --subscribe space.$sid aerospace_workspace_change \
            --set space.$sid \
            icon.drawing=off \
            label="$sid" \
            label.font="MonoLisa Nerd Font:Regular:14.0" \
            label.color=$WORKSPACE_INACTIVE \
            label.padding_left=8 \
            label.padding_right=8 \
            click_script="aerospace workspace $sid" \
            script="$HOME/.config/sketchybar/plugins/aerospace.sh $sid"
    done

    # Add final spacer
    sketchybar --add item spacer left \
               --set spacer icon="|" icon.color=$GREY icon.font="Hack Nerd Font:Regular:14.0" label.drawing=off

    # Move current_app to the end
    sketchybar --move current_app after spacer 2>/dev/null
fi

# Always update workspace colors (fast operation, no flickering)
for sid in $ALL_WORKSPACES; do
    if [ "$sid" = "$FOCUSED_WS" ]; then
        sketchybar --set space.$sid label.color=$WHITE
    else
        sketchybar --set space.$sid label.color=$WORKSPACE_INACTIVE
    fi
done