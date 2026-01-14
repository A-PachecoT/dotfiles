#!/bin/bash

# Hard reset: Force quit and reopen SketchyBar, AeroSpace, and HammerSpoon
# Useful when apps are hung and reload doesn't work

# Kill ALL SketchyBar processes including zombie triggers
pkill -9 sketchybar 2>/dev/null
sleep 0.5
/opt/homebrew/bin/brew services restart sketchybar

# Force quit HammerSpoon and reopen
killall Hammerspoon 2>/dev/null
sleep 0.5
open -a Hammerspoon

# For AeroSpace, we need to background this since we're running from within AeroSpace
# Give it a moment to finish executing this script, then force quit and reopen
(
    sleep 1
    killall AeroSpace 2>/dev/null
    sleep 0.5
    open -a AeroSpace
) &

# Show notification
osascript -e 'display notification "Force restarting SketchyBar, AeroSpace, and HammerSpoon" with title "Hard Reset"'
