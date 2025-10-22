#!/bin/bash

# TuneUp SketchyBar Plugin
# Muestra el perfil de audio activo en la barra de estado

# Get current profile from HammerSpoon
if command -v hs &> /dev/null; then
    PROFILE_DATA=$(hs -c "local p = tuneup.getCurrentProfile(); if p then print(p.icon .. '|' .. p.name) end" 2>/dev/null)

    if [ -n "$PROFILE_DATA" ]; then
        PROFILE_ICON="${PROFILE_DATA%|*}"
        PROFILE_NAME="${PROFILE_DATA#*|}"
    else
        # Fallback si HammerSpoon no responde
        PROFILE_ICON="${ICON:-🎵}"
        PROFILE_NAME="${PROFILE:-Normal}"
    fi
else
    # Fallback si hs no está disponible
    PROFILE_ICON="${ICON:-🎵}"
    PROFILE_NAME="${PROFILE:-Normal}"
fi

# Colores del tema Tokyo Night
ICON_COLOR="0xff7aa2f7"
TEXT_COLOR="0xffcdd6f4"

# Actualizar item de SketchyBar
sketchybar --set tuneup \
    icon="$PROFILE_ICON" \
    icon.color="$ICON_COLOR" \
    label="$PROFILE_NAME" \
    label.color="$TEXT_COLOR"
