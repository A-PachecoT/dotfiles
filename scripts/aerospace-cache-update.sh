#!/bin/bash
# Updates aerospace workspace cache file
# Called by trigger script, writes to cache for Lua to read (non-blocking)

CACHE_FILE="/tmp/aerospace-workspace-cache"

# Get focused workspace
FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null | head -1)

# Get occupied workspaces per monitor
OCCUPIED_1=$(aerospace list-workspaces --monitor 1 --empty no 2>/dev/null | tr '\n' ' ')
OCCUPIED_2=$(aerospace list-workspaces --monitor 2 --empty no 2>/dev/null | tr '\n' ' ')

# Get apps per occupied workspace
declare -A APPS
for ws in $OCCUPIED_1 $OCCUPIED_2; do
  APPS[$ws]=$(aerospace list-windows --workspace "$ws" --format '%{app-name}' 2>/dev/null | tr '\n' '|')
done

# Write cache atomically (write to temp then move)
TEMP_FILE="${CACHE_FILE}.tmp.$$"
{
  echo "FOCUSED=$FOCUSED"
  echo "OCCUPIED_1=$OCCUPIED_1"
  echo "OCCUPIED_2=$OCCUPIED_2"
  for ws in "${!APPS[@]}"; do
    echo "APPS_$ws=${APPS[$ws]}"
  done
  echo "UPDATED=$(date +%s)"
} > "$TEMP_FILE"

mv "$TEMP_FILE" "$CACHE_FILE"
