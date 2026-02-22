#!/bin/bash
# Simple workspace trigger for SketchyBar
# Just triggers sketchybar with FOCUSED_WORKSPACE - no aerospace calls
# Uses lock + epoch seconds debounce (macOS compatible)

LOCK_DIR="/tmp/sketchybar-ws-trigger.lock"
STATE_FILE="/tmp/sketchybar-ws-trigger.state"

FOCUSED_WORKSPACE="${1:-$AEROSPACE_FOCUSED_WORKSPACE}"

# Try to acquire lock (atomic mkdir)
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

# Debounce using epoch seconds (macOS date doesn't support %N)
# Only allow one trigger per second
NOW=$(date +%s)
if [[ -f "$STATE_FILE" ]]; then
  LAST=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
  if [[ "$NOW" == "$LAST" ]]; then
    exit 0
  fi
fi

echo "$NOW" > "$STATE_FILE"

# Log for debugging (remove after verified working)
echo "$(date '+%H:%M:%S') WS=$FOCUSED_WORKSPACE" >> /tmp/sketchybar-trigger.log

# Trigger sketchybar
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$FOCUSED_WORKSPACE" 2>/dev/null &
