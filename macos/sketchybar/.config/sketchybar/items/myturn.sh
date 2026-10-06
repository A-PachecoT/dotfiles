#!/bin/bash
# myturn — quién te espera, en la barra (reemplaza al widget de Spotify). SSOT: ~/dotfiles/docs/myturn.md
# Los labels los pinta `myturn sketchybar`; aquí solo se declaran los items (filas fijas por sección).

PLUGIN="$HOME/.config/sketchybar/plugins/myturn.sh"  # también es el wrapper con PATH para los clics
FONT="SF Pro"
NERD="Hack Nerd Font"
WHITE=0xffe5e9f0
DIM=0xff9aa3b5

row=(icon.drawing=off label.font="$FONT:Regular:13.0" label.color=$WHITE padding_left=12 padding_right=12
  background.drawing=off)
hdr=(icon.drawing=off label.font="$FONT:Bold:10.0" label.color=$DIM padding_left=12 padding_right=12
  background.drawing=off drawing=off)

sketchybar --add event myturn_update \
  --add item myturn center \
  --set myturn script="$PLUGIN" update_freq=20 updates=on \
    icon.font="$NERD:Regular:16.0" icon=󰄲 icon.padding_right=6 padding_right=14 \
    label.font="$FONT:Semibold:13.0" label.max_chars=48 \
    popup.align=center \
  --subscribe myturn mouse.entered mouse.exited.global myturn_update system_woke \
  --add item myturn.empty popup.myturn \
  --set myturn.empty "${row[@]}" label="Nada prioritario · ⌥T prioriza el agente enfocado o captura algo" label.color=$DIM

add_section() {  # $1 = clave (w|k|p), $2 = filas
  sketchybar --add item myturn.h.$1 popup.myturn --set myturn.h.$1 "${hdr[@]}"
  for ((i = 0; i < $2; i++)); do
    sketchybar --add item myturn.$1.$i popup.myturn \
      --set myturn.$1.$i "${row[@]}" drawing=off click_script="$PLUGIN click $1.$i"
  done
}
add_section w 4   # te esperan
add_section k 3   # trabajando
add_section z 3   # en pausa (vista, sigue siendo tuya)
add_section p 3   # pendientes

sketchybar --add item myturn.footer popup.myturn \
  --set myturn.footer "${row[@]}" label.font="$FONT:Regular:11.0" label.color=$DIM

"$PLUGIN" sketchybar >/dev/null 2>&1 &
