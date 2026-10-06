#!/bin/bash
# myturn — tus tareas y quién te espera, en la barra (reemplaza al widget de Spotify). SSOT: ~/dotfiles/docs/myturn.md
# Clic (o ⌥T) abre el panel de Hammerspoon: anotar, editar, prioridad, copiar para Claude, ir al agente.

PLUGIN="$HOME/.config/sketchybar/plugins/myturn.sh"
FONT="SF Pro"

sketchybar --add event myturn_update \
  --add item myturn center \
  --set myturn script="$PLUGIN" update_freq=20 updates=on \
    icon="○" icon.font="$FONT:Bold:14.0" icon.padding_right=6 padding_right=14 \
    label.font="$FONT:Semibold:13.0" label.max_chars=56 \
    click_script="open -g 'hammerspoon://myturn-panel'" \
  --subscribe myturn myturn_update system_woke

"$PLUGIN" >/dev/null 2>&1 &
