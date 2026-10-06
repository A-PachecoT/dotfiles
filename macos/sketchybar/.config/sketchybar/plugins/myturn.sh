#!/bin/bash
# Repinta la etiqueta del item `myturn` (cada 20 s y en myturn_update). El panel vive en Hammerspoon.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"  # sketchybar arranca con PATH mínimo
exec "$HOME/.local/bin/myturn" sketchybar
