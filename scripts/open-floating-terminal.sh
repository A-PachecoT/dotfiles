#!/bin/bash
# Open Ghostty as a floating window in the current workspace
# Usage: open-floating-terminal.sh

# Open new Ghostty instance
open -na "Ghostty"

# Wait for window to appear and get focus
sleep 0.3

# Set to floating layout
aerospace layout floating
