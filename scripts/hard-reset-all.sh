#!/bin/bash

# Hard reset: Force quit and reopen SketchyBar and HammerSpoon.
# Useful when their event loops wedge and `--reload` doesn't recover them.
#
# AeroSpace is intentionally NOT restarted here: restarting it reshuffles all
# workspaces/spaces. The navbar freeze is a cross-process deadlock between
# SketchyBar and AeroSpace, and restarting SketchyBar alone clears it (once one
# side restarts, the mutual wait is broken).

# Kill ALL SketchyBar processes including zombie triggers, then restart fresh.
# This recovers a wedged event loop that `sketchybar --reload` cannot.
pkill -9 sketchybar 2>/dev/null
sleep 0.5
/opt/homebrew/bin/brew services restart sketchybar

# Force quit HammerSpoon and reopen
killall Hammerspoon 2>/dev/null
sleep 0.5
open -a Hammerspoon

# Show notification
osascript -e 'display notification "Force restarting SketchyBar and HammerSpoon" with title "Hard Reset"'
