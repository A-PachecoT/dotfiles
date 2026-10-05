#!/bin/bash
# Eventos del item tk.anchor. El pintado lo hace `tk sketchybar` (lee ~/tasks, herdr y escribe los labels).
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"  # sketchybar arranca con PATH mínimo
TK="$HOME/.local/bin/tk"

# Con argumentos es un wrapper: los click_script llaman `plugins/tk.sh click now.done`.
[ $# -gt 0 ] && exec "$TK" "$@"

case "$SENDER" in
  mouse.entered)
    sketchybar --set tk.anchor popup.drawing=on
    "$TK" sketchybar
    ;;
  mouse.exited.global)
    sketchybar --set tk.anchor popup.drawing=off
    ;;
  *)
    "$TK" sketchybar
    ;;
esac
