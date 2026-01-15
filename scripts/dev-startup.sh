#!/bin/bash
# Launch Ghostty windows with specific tmux sessions
# Called from AeroSpace after-startup-command
# Each window title shows session name → AeroSpace routes to correct workspace

sleep 1  # Wait for AeroSpace to be ready

# Workspace 2: Cofoundy
/Applications/Ghostty.app/Contents/MacOS/ghostty -e "tmux new -A -s cofoundy" &
sleep 0.5

# Workspace 3: Bilio
/Applications/Ghostty.app/Contents/MacOS/ghostty -e "tmux new -A -s bilio" &
sleep 0.5

# Workspace 4: Personal
/Applications/Ghostty.app/Contents/MacOS/ghostty -e "tmux new -A -s personal" &
sleep 0.5

# Workspace 9: Notes (simple claude for Obsidian assistance)
/Applications/Ghostty.app/Contents/MacOS/ghostty -e "tmux new -A -s notes" &
