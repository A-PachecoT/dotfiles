#!/bin/bash
# Eventos del item `myturn`. El pintado lo hace `myturn sketchybar` (lee ~/tasks y herdr, escribe los labels).
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"  # sketchybar arranca con PATH mínimo
MYTURN="$HOME/.local/bin/myturn"

# Con argumentos es un wrapper: los click_script llaman `plugins/myturn.sh click w.0`.
[ $# -gt 0 ] && exec "$MYTURN" "$@"

case "$SENDER" in
  mouse.entered)
    sketchybar --set myturn popup.drawing=on
    "$MYTURN" sketchybar
    ;;
  mouse.exited.global)
    sketchybar --set myturn popup.drawing=off
    ;;
  *)
    "$MYTURN" sketchybar
    ;;
esac
