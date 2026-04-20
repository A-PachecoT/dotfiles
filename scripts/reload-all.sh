#!/bin/bash

# Reload all three apps: SketchyBar, AeroSpace, and HammerSpoon

# Reload SketchyBar
/opt/homebrew/bin/sketchybar --reload

# Reload AeroSpace configuration
/opt/homebrew/bin/aerospace reload-config

# Reload HammerSpoon via URL scheme
# Avoids both `hs` CLI PATH conflicts (HubSpot CLI shadows it) and
# the requirement for hs.allowAppleScript(true) in init.lua.
open -g "hammerspoon://reload"

# Show notification that reload is complete
osascript -e 'display notification "SketchyBar, AeroSpace, and HammerSpoon reloaded" with title "Configuration Reloaded"'
