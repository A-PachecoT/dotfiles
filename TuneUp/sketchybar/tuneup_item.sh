#!/bin/bash

# TuneUp SketchyBar Item Configuration
# Agregar este contenido a tu sketchybarrc para habilitar el widget

# IMPORTANTE: Este archivo es solo de referencia.
# Copia el contenido de TUNEUP_ITEM_CONFIG al final de tu ~/.config/sketchybar/sketchybarrc

cat <<'TUNEUP_ITEM_CONFIG'

# ===============================================
# TuneUp - Audio Profile Widget
# ===============================================

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

sketchybar --add event tuneup_profile_change \
           --add item tuneup right \
           --set tuneup \
                 icon=🎵 \
                 icon.font="Hack Nerd Font:Bold:16.0" \
                 icon.padding_left=8 \
                 icon.padding_right=4 \
                 label="Normal" \
                 label.font="SF Pro:Semibold:12.0" \
                 label.padding_right=8 \
                 background.color=0xff1a1b26 \
                 background.corner_radius=6 \
                 background.height=24 \
                 background.padding_left=4 \
                 background.padding_right=4 \
                 script="$PLUGIN_DIR/tuneup.sh" \
                 click_script="hs -c 'tuneup.toggleProfile()'" \
           --subscribe tuneup tuneup_profile_change

TUNEUP_ITEM_CONFIG
