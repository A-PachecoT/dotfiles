#!/bin/bash
# tk — la tarea de ahora en la barra + popup (reemplaza al widget de Spotify). SSOT: ~/dotfiles/docs/tk.md
# Los labels los pinta `tk sketchybar`; aquí solo se declaran los items.

PLUGIN="$HOME/.config/sketchybar/plugins/tk.sh"
TK="$PLUGIN"  # wrapper con PATH
FONT="SF Pro"
NERD="Hack Nerd Font"
WHITE=0xffe5e9f0
DIM=0xff9aa3b5
ACCENT=0xff88c0d0
BTN_BG=0xff3b4252

row=(icon.drawing=off label.font="$FONT:Regular:13.0" padding_left=12 padding_right=12 background.drawing=off)
btn=(label.font="$FONT:Semibold:13.0" label.color=$WHITE icon.font="$NERD:Regular:14.0" icon.color=$ACCENT
  icon.padding_left=12 icon.padding_right=6 label.padding_right=12
  background.color=$BTN_BG background.corner_radius=8 background.height=26 background.drawing=on)

sketchybar --add event tk_update \
  --add item tk.anchor center \
  --set tk.anchor script="$PLUGIN" update_freq=20 updates=on \
    icon.font="$NERD:Regular:16.0" icon=󰄱 icon.padding_right=6 padding_right=14 \
    label.font="$FONT:Semibold:13.0" label.max_chars=42 \
    popup.align=center popup.height=30 \
  --subscribe tk.anchor mouse.entered mouse.exited.global tk_update system_woke \
  \
  --add item tk.now.title popup.tk.anchor \
  --set tk.now.title "${row[@]}" label.font="$FONT:Heavy:15.0" label.color=$WHITE \
  --add item tk.now.why popup.tk.anchor \
  --set tk.now.why "${row[@]}" label.font="$FONT:Regular:12.0" label.color=$DIM \
  \
  --add item tk.act.go popup.tk.anchor \
  --set tk.act.go "${btn[@]}" icon=󰁕 label="Trabajar" click_script="$TK click now.go" \
  --add item tk.act.done popup.tk.anchor \
  --set tk.act.done "${btn[@]}" icon=󰄬 label="Hecha" click_script="$TK click now.done" \
  --add item tk.act.next popup.tk.anchor \
  --set tk.act.next "${btn[@]}" icon=󰒭 label="Siguiente (45 min)" click_script="$TK click now.next" \
  --add item tk.act.snooze popup.tk.anchor \
  --set tk.act.snooze "${btn[@]}" icon=󰒲 label="Mañana" click_script="$TK click now.snooze" \
  \
  --add item tk.sep popup.tk.anchor \
  --set tk.sep "${row[@]}" label="SIGUIENTES" label.font="$FONT:Bold:10.0" label.color=$DIM

for i in 0 1 2; do
  sketchybar --add item tk.next.$i popup.tk.anchor \
    --set tk.next.$i "${row[@]}" label.color=$WHITE click_script="$TK click next.$i"
done

sketchybar --add item tk.footer popup.tk.anchor \
  --set tk.footer "${row[@]}" label.font="$FONT:Regular:11.0" label.color=$DIM \
    click_script="$TK sessions > /tmp/tk-sessions.txt; open -a TextEdit /tmp/tk-sessions.txt"

"$TK" sketchybar >/dev/null 2>&1 &
