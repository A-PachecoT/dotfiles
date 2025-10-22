#!/bin/bash

# TuneUp SketchyBar Plugin
# Muestra el perfil de audio activo en la barra de estado

source "$HOME/.config/sketchybar/themes/tokyo-night/colors.sh" 2>/dev/null || true

# Configuración por defecto si no se carga el tema
PROFILE_ICON="${ICON:-🎵}"
PROFILE_NAME="${PROFILE:-Normal}"

# Colores del tema Tokyo Night (fallback si no carga)
TEXT_COLOR="${TEXT_COLOR:-0xffc0caf5}"
ICON_COLOR="${ICON_COLOR:-0xff7aa2f7}"
BG_COLOR="${BG_COLOR:-0xff1a1b26}"

# Actualizar item de SketchyBar
sketchybar --set tuneup \
    icon="$PROFILE_ICON" \
    icon.color="$ICON_COLOR" \
    label="$PROFILE_NAME" \
    label.color="$TEXT_COLOR" \
    background.color="$BG_COLOR"
