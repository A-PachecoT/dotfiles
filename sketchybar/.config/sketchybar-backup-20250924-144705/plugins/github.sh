#!/bin/bash

source "$HOME/.config/sketchybar/themes/tokyo-night"
source "$HOME/.config/sketchybar/icons.sh"

# Requires GitHub CLI (gh) to be installed and authenticated
# Install: brew install gh
# Auth: gh auth login

COUNT=$(gh api notifications --paginate | jq 'length' 2>/dev/null || echo "0")

if [ "$COUNT" -gt 0 ]; then
  sketchybar --set github.bell icon=$BELL_DOT \
                              label="$COUNT" \
                              label.drawing=on \
                              icon.color=$ORANGE
else
  sketchybar --set github.bell icon=$BELL \
                              label.drawing=off \
                              icon.color=$GREY
fi