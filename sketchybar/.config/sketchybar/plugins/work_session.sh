#!/bin/bash

# Work session indicator for SketchyBar
# Shows moon icon when work session is active

WORK_SESSION_PID=$(pgrep -f "caffeinate -i -t")

if [ -n "$WORK_SESSION_PID" ]; then
    # Calculate remaining time
    START_TIME=$(ps -o lstart= -p $WORK_SESSION_PID | xargs -I {} date -j -f "%a %b %d %T %Y" "{}" "+%s" 2>/dev/null)
    CURRENT_TIME=$(date +%s)

    if [ -n "$START_TIME" ]; then
        # Get caffeinate command to extract duration
        CAFFEINATE_CMD=$(ps -o command= -p $WORK_SESSION_PID)
        DURATION=$(echo $CAFFEINATE_CMD | grep -o '\-t [0-9]*' | awk '{print $2}')

        if [ -n "$DURATION" ]; then
            END_TIME=$((START_TIME + DURATION))
            REMAINING=$((END_TIME - CURRENT_TIME))

            if [ $REMAINING -gt 0 ]; then
                HOURS=$((REMAINING / 3600))
                MINUTES=$(((REMAINING % 3600) / 60))

                sketchybar --set $NAME \
                    icon="🌙" \
                    label="${HOURS}h ${MINUTES}m" \
                    icon.color=0xffbb9af7 \
                    label.color=0xffbb9af7 \
                    drawing=on
            else
                sketchybar --set $NAME drawing=off
            fi
        else
            # Session active but no timer
            sketchybar --set $NAME \
                icon="🌙" \
                label="Active" \
                icon.color=0xffbb9af7 \
                label.color=0xffbb9af7 \
                drawing=on
        fi
    else
        sketchybar --set $NAME drawing=off
    fi
else
    sketchybar --set $NAME drawing=off
fi