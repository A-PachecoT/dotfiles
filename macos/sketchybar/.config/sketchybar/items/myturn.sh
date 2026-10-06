#!/bin/bash
# myturn — tus prioridades en la barra (reemplaza al widget de Spotify). SSOT: ~/dotfiles/docs/myturn.md
# Un solo concepto: las prioridades. Clic en una fila = ir a ese agente. Los textos los pinta `myturn sketchybar`.

PLUGIN="$HOME/.config/sketchybar/plugins/myturn.sh"  # también es el wrapper con PATH para los clics
FONT="SF Pro"
WHITE=0xffe5e9f0
DIM=0xff9aa3b5

sketchybar --add event myturn_update \
  --add item myturn center \
  --set myturn script="$PLUGIN" update_freq=20 updates=on \
    icon="○" icon.font="$FONT:Bold:14.0" icon.padding_right=6 padding_right=14 \
    label.font="$FONT:Semibold:13.0" label.max_chars=56 \
    popup.align=center \
  --subscribe myturn mouse.entered mouse.exited.global myturn_update system_woke \
  \
  --add item myturn.title popup.myturn \
  --set myturn.title icon.drawing=off label="MIS PRIORIDADES" label.font="$FONT:Bold:10.0" label.color=$DIM \
    padding_left=12 padding_right=12 \
  --add item myturn.empty popup.myturn \
  --set myturn.empty icon.drawing=off label="Sin prioridades. Mira un agente en herdr y presiona ⌥T." \
    label.font="$FONT:Regular:13.0" label.color=$WHITE padding_left=12 padding_right=12

for i in 0 1 2 3 4 5; do
  sketchybar --add item myturn.r.$i popup.myturn \
    --set myturn.r.$i drawing=off icon.font="$FONT:Bold:13.0" icon.padding_right=8 \
      label.font="$FONT:Regular:13.0" label.color=$WHITE padding_left=12 padding_right=12 \
      click_script="$PLUGIN click r.$i"
done

sketchybar --add item myturn.hint popup.myturn \
  --set myturn.hint icon.drawing=off label.font="$FONT:Regular:11.0" label.color=$DIM \
    padding_left=12 padding_right=12

"$PLUGIN" sketchybar >/dev/null 2>&1 &
