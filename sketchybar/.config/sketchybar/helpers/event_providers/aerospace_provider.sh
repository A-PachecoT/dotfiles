#!/bin/bash

# AeroSpace event provider for SketchyBar
# Monitors workspace changes and triggers SketchyBar events

while true; do
  # Get current focused workspace
  FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null)

  if [ -n "$FOCUSED" ]; then
    sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$FOCUSED"
  fi

  sleep 0.5
done