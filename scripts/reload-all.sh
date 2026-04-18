#!/bin/bash

# Reload all three apps: SketchyBar, AeroSpace, and HammerSpoon

# Reload SketchyBar
/opt/homebrew/bin/sketchybar --reload

# Reload AeroSpace configuration
/opt/homebrew/bin/aerospace reload-config

# Reload HammerSpoon (using AppleScript to avoid CLI port issues)
osascript -e 'tell application "Hammerspoon" to reload' 2>/dev/null

# Show notification that reload is complete
osascript -e 'display notification "SketchyBar, AeroSpace, and HammerSpoon reloaded" with title "Configuration Reloaded"'
