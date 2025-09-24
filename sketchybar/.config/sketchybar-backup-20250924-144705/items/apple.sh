#!/bin/bash
# Apple Menu Item

source "$HOME/.config/sketchybar/themes/tokyo-night"
source "$HOME/.config/sketchybar/icons.sh"

POPUP_OFF='sketchybar --set apple.logo popup.drawing=off'
POPUP_CLICK_SCRIPT='sketchybar --set $NAME popup.drawing=toggle'

apple_logo=(
  icon=$APPLE
  icon.font="$FONT:Black:18.0"
  icon.color=$GREEN
  background.padding_right=15
  padding_right=10
  label.drawing=off
  click_script="$POPUP_CLICK_SCRIPT"
)

apple_prefs=(
  icon=$PREFERENCES
  label="Preferences"
  click_script="open -a 'System Preferences'; $POPUP_OFF"
)

apple_activity=(
  icon=$ACTIVITY
  label="Activity Monitor"
  click_script="open -a 'Activity Monitor'; $POPUP_OFF"
)

apple_lock=(
  icon=$LOCK
  label="Lock Screen"
  click_script="pmset displaysleepnow; $POPUP_OFF"
)

sketchybar --add item apple.logo left \
           --set apple.logo "${apple_logo[@]}" \
           \
           --add item apple.prefs popup.apple.logo \
           --set apple.prefs "${apple_prefs[@]}" \
           \
           --add item apple.activity popup.apple.logo \
           --set apple.activity "${apple_activity[@]}" \
           \
           --add item apple.lock popup.apple.logo \
           --set apple.lock "${apple_lock[@]}"